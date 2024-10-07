# File: setup_project.ps1

# Root project directory
$projectDir = "content-analysis-generation-app"

# Create root directory
New-Item -ItemType Directory -Path $projectDir

# Create frontend (client) structure
New-Item -ItemType Directory -Path "$projectDir/client/public" -Force
New-Item -ItemType Directory -Path "$projectDir/client/src" -Force

# Create necessary files for the frontend
Set-Content -Path "$projectDir/client/package.json" -Value @'
{
  "name": "client",
  "version": "1.0.0",
  "private": true,
  "homepage": "https://<your-github-username>.github.io/content-analysis-generation-app",
  "dependencies": {
    "axios": "^0.21.1",
    "react": "^17.0.1",
    "react-dom": "^17.0.1",
    "react-scripts": "4.0.0"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject",
    "predeploy": "npm run build",
    "deploy": "gh-pages -d build"
  }
}
'@

Set-Content -Path "$projectDir/client/.env" -Value "REACT_APP_BACKEND_URL=https://your-backend-host.com"

# Create frontend application entry point (App.js)
Set-Content -Path "$projectDir/client/src/App.js" -Value @'
import React, { useState } from "react";
import axios from "axios";
import "./App.css";

function App() {
  const [content, setContent] = useState("");
  const [analysisReport, setAnalysisReport] = useState(null);
  const [generatedContent, setGeneratedContent] = useState([]);
  const [topic, setTopic] = useState("");
  const [keyword, setKeyword] = useState("");
  const [length, setLength] = useState("short");
  const [quantity, setQuantity] = useState(1);

  const handleAnalyze = async () => {
    try {
      const response = await axios.post("/api/analyze", { content });
      setAnalysisReport(response.data.analysisReport);
    } catch (error) {
      console.error("Error analyzing content", error);
    }
  };

  const handleGenerate = async () => {
    try {
      const response = await axios.post("/api/generate", { topic, keyword, length, quantity });
      setGeneratedContent(response.data.generatedContent);
    } catch (error) {
      console.error("Error generating content", error);
    }
  };

  const handleDownload = async () => {
    try {
      const response = await axios.get("/api/download", { responseType: "blob" });
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement("a");
      link.href = url;
      link.setAttribute("download", "generated_content.csv");
      document.body.appendChild(link);
      link.click();
    } catch (error) {
      console.error("Error downloading CSV", error);
    }
  };

  return (
    <div className="App">
      <h1>Content Analysis and Generation App</h1>

      <div className="analyze-section">
        <textarea
          value={content}
          onChange={(e) => setContent(e.target.value)}
          placeholder="Paste your content here..."
        />
        <button onClick={handleAnalyze}>Analyze Content</button>
        {analysisReport && <div className="report">{JSON.stringify(analysisReport)}</div>}
      </div>

      <div className="generate-section">
        <input type="text" value={topic} onChange={(e) => setTopic(e.target.value)} placeholder="Enter topic" />
        <input type="text" value={keyword} onChange={(e) => setKeyword(e.target.value)} placeholder="Enter keyword" />
        <select value={length} onChange={(e) => setLength(e.target.value)}>
          <option value="short">Short</option>
          <option value="medium">Medium</option>
          <option value="large">Large</option>
        </select>
        <select value={quantity} onChange={(e) => setQuantity([e.target.value])}>
          <option value={1}>1</option>
          <option value={5}>5</option>
          <option value={10}>10</option>
        </select>
        <button onClick={handleGenerate}>Generate Content</button>
        {generatedContent.length > 0 && (
          <div className="generated-content">
            {generatedContent.map((content, index) => (
              <div key={index}>{content}</div>
            ))}
          </div>
        )}
      </div>

      <button onClick={handleDownload}>Download CSV</button>
    </div>
  );
}

export default App;
'@

# Create backend (server) structure
New-Item -ItemType Directory -Path "$projectDir/server" -Force

# Create necessary files for the backend
Set-Content -Path "$projectDir/server/package.json" -Value @'
{
  "name": "server",
  "version": "1.0.0",
  "main": "index.js",
  "dependencies": {
    "express": "^4.17.1",
    "cors": "^2.8.5",
    "dotenv": "^8.2.0",
    "csv-writer": "^1.6.0",
    "openai": "^1.0.0"
  },
  "scripts": {
    "start": "node index.js"
  }
}
'@

# Add environment variable file for backend
Set-Content -Path "$projectDir/server/.env" -Value "OPENAI_API_KEY=your-openai-api-key"

# Add backend application entry point (index.js)
Set-Content -Path "$projectDir/server/index.js" -Value @'
const express = require("express");
const cors = require("cors");
const { Configuration, OpenAIApi } = require("openai");
const csvWriter = require("csv-writer").createObjectCsvWriter;

const app = express();
app.use(cors());
app.use(express.json());

const configuration = new Configuration({
  apiKey: process.env.OPENAI_API_KEY,
});
const openai = new OpenAIApi(configuration);

app.post("/api/analyze", async (req, res) => {
  const { content } = req.body;
  const analysisReport = {
    tone: "neutral",
    sentiment: "positive",
    linguisticTraits: ["formal", "informative"],
  };
  res.json({ analysisReport });
});

app.post("/api/generate", async (req, res) => {
  const { topic, keyword, length, quantity } = req.body;
  try {
    const prompts = Array(quantity).fill(`Write a ${length} article about ${topic} focusing on ${keyword}.`);
    const generatedContent = await Promise.all(
      prompts.map(async (prompt) => {
        const response = await openai.createCompletion({
          model: "text-davinci-003",
          prompt,
          max_tokens: length === "short" ? 150 : length === "medium" ? 400 : 700,
        });
        return response.data.choices[0].text.trim();
      })
    );
    res.json({ generatedContent });
  } catch (error) {
    console.error("Error generating content", error);
    res.status(500).send("Error generating content");
  }
});

app.get("/api/download", (req, res) => {
  const csvPath = "generated_content.csv";
  const csvWriterInstance = csvWriter({
    path: csvPath,
    header: [
      { id: "title", title: "Title" },
      { id: "content", title: "Content" },
      { id: "keyword", title: "Keyword" },
      { id: "createdAt", title: "Creation Date" },
    ],
  });
  const data = [
    { title: "Sample Title", content: "Sample content here...", keyword: "sample", createdAt: new Date().toISOString() },
  ];
  csvWriterInstance
    .writeRecords(data)
    .then(() => {
      res.download(csvPath);
    })
    .catch((error) => {
      console.error("Error writing CSV", error);
      res.status(500).send("Error generating CSV");
    });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
'@

# Create README file
Set-Content -Path "$projectDir/README.md" -Value @'
# Content Analysis and Generation Web App

## Overview
This is a web application that allows users to analyze their writing style, generate new content, and download it in a structured format.

## Project Structure
- **client/**: Contains the React.js frontend.
- **server/**: Contains the Node.js backend.

## Setup Instructions

### Frontend
1. Navigate to the client folder:
