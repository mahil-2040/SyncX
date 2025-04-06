import { io } from "socket.io-client";
import { getLocalIPAddress } from "./getIp.js";

const host = getLocalIPAddress();// this should be server ip address

const socket = io(`http://${host}:9000`);

socket.on("connect", () => {
  const socketId = "xDcAQ24V_uYK4iveAAAB";
  socket.emit("directMessage", { socketId, msg: "HOP HOP" });
});
