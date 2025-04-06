import { io } from "socket.io-client";
import { getLocalIPAddress } from "./getIp.js";
import { getFolderContents } from "./construcFileList.js";

const host = getLocalIPAddress();

const socket = io(`http://${host}:9000`);

  socket.on("connect", () => {
    console.log("Connected to server with socket ID:", socket.id);
    socket.emit("groupMessage", {msg : "Hello from client", user : "Aki"});
});
