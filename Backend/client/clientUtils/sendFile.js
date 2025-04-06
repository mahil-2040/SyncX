import WebSocket, { WebSocketServer } from "ws";
import { createReadStream } from "fs";
import { basename } from "path";
import { getLocalIPAddress } from "./getIp.js";

const senderIP = getLocalIPAddress(); // Sender's IPv4 address

export const startSendingFile = (filePath, availablePort) => {
  const wss = new WebSocketServer({ host: senderIP, port: availablePort });

  console.log(`WebSocket server started at ws://${senderIP}:${availablePort}`);

  wss.on("connection", (ws) => {
    console.log("Receiver connected.");
    const fileName = basename(filePath);

    ws.send(JSON.stringify({ type: "startFile", fileName }));
    const stream = createReadStream(filePath, { highWaterMark: 64 * 1024 });

    stream.on("data", (chunk) => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(chunk, { binary: true });
      }
    });

    stream.on("end", () => {
      ws.send(JSON.stringify({ type: "endOfFile" }));
      console.log("File transfer complete.");
      ws.close();
      wss.close(() => {
        console.log("WebSocket server closed, releasing port.");
      });
    });

    stream.on("error", (err) => {
      console.error("Error reading file:", err);
      ws.send(JSON.stringify({ type: "error", message: "File read error" }));
      ws.close();
      wss.close();
    });

    ws.on("close", () => {
      console.log("Receiver disconnected.");
    });
  });

  wss.on("close", () => {
    console.log("WebSocket server fully shut down.");
  });

  wss.on("error", (err) => {
    console.error("WebSocket Server Error:", err.message);
  });
};
