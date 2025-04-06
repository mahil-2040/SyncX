import WebSocket from "ws";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export const startReceivingFile = (senderIP, senderPort) => {
  const ws = new WebSocket(`http://${senderIP}:${senderPort}`);

  const publicFolder = path.join(__dirname, "public");
  if (!fs.existsSync(publicFolder)) {
    fs.mkdirSync(publicFolder);
  }

  let fileStream = null;
  let filePath = null;

  ws.on("open", () => {
    console.log("Connected to sender.");
  });

  ws.on("message", (message) => {
    try {
      const data = JSON.parse(message);

      if (data.type === "startFile") {
        const fileName = data.fileName || "downloaded_file";
        filePath = path.join(publicFolder, fileName);
        fileStream = fs.createWriteStream(filePath);
        console.log(`Receiving file: ${fileName}`);
      } else if (data.type === "fileChunk") {
        if (fileStream) {
          fileStream.write(Buffer.from(data.chunk, "base64"));
        }
      } else if (data.type === "endOfFile") {
        if (fileStream) {
          fileStream.end();
          console.log(`File received and saved at: ${filePath}`);
        }
        ws.close();
      }
    } catch (err) {
      console.error("Error processing message:", err);
    }
  });

  ws.on("close", () => {
    console.log("Disconnected from sender.");
    if (fileStream) {
      fileStream.end();
    }
  });

  ws.on("error", (err) => {
    console.error("WebSocket error:", err.message);
  });
};
