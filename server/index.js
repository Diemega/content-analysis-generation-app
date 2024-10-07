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
