import { io } from "socket.io-client";
import { getFolderContents } from "./construcFileList.js";
import { getLocalIPAddress } from "./getIp.js";
import { startSendingFile } from "./sendFile.js";
import getPort from "get-port";

const host = getLocalIPAddress();

const socket = io(`http://${host}:9000`);

socket.on("connect", () => {
  console.log("Connected to server with socket ID:", socket.id);
  socket.emit(
    "register",
    {
      username: "Heloo User",
      ip: host,
      fileList: getFolderContents("C:\\Users\\Hp\\Downloads\\"),
    },
    (response) => {
      if (response.success) {
        console.log("Registration successful:", response.message);
      } else {
        console.error("Registration failed:", response.message);
      }
    }
  );
});
socket.on("dmessage", (data) => {
  console.log(`Direct Message from ${data.user}:, ${data.message} `);
});
socket.on("gmessage", (data) => {
  console.log(`Group Message from ${data.user}:, ${data.message} `);
});
socket.on("connect_error", (err) => {
  console.error("Connection error:", err.message);
});
socket.on("fileRequest", async (data) => {
  console.log("File path:", data.file);
  const availablePort = await getPort();
  //send logic
  socket.emit("portInfo", { availablePort, userSocketId : data.userSocketId });
  startSendingFile(data.file, availablePort);
});
socket.on("disconnect", () => {
  console.log("Disconnected from server.");
});
