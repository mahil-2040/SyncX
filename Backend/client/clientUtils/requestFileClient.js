import { io } from "socket.io-client";
import { startReceivingFile } from "./recieveFile.js";
import { getLocalIPAddress } from "./getIp.js";

const ip = getLocalIPAddress();
const socket = io(`http://${ip}:9000`);
let availablePort = null;

socket.on("connect", async () => {
  console.log("Connected to server with socket ID:", socket.id);
  socket.emit("requestFile", {
    fileId: "67e54e51b6be51ae8fc6964a",
  });
  if (availablePort === null) {
    console.log("Waiting for available port...");
    let timer = setInterval(async () => {
      if (availablePort !== null) {
        console.log(`Port found: ${availablePort}. Starting file download.`);
        clearInterval(timer);
        startReceivingFile("192.168.137.227",availablePort);
        availablePort = null;
      } else {
        console.log("Port not found yet. Retrying...");
      }
    }, 100);
  } else {
    startReceivingFile(availablePort);
    availablePort = null;
  }
});

socket.on("free-port", (data) => {
  availablePort = data.availablePort;
});
