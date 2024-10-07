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
