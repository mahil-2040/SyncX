import cors from "cors";
import express, { urlencoded } from "express";
import http from "http";
import { Server } from "socket.io";
import path from "path";
import { registerHandler } from "./eventHandlers/userEvents.handler.js";
import { User } from "./models/user.model.js";
import { File } from "./models/file.model.js";

const app = express();

// middleware
app.use(
  cors({
    origin: process.env.CORS_ORIGIN,
    credentials: true,
  })
);

app.use(express.json({ limit: "20kb" }));
app.use(urlencoded({ extended: true, limit: "16kb" }));
app.use(express.static(path.resolve("./public")));

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["PUT", "GET"],
  },
});
// http events

import userRouter from "./routes/user.routes.js";
import { Message } from "./models/message.model.js";

app.use("/api/users", userRouter);

// socket events
io.on("connection", (socket) => {
  console.log("New client connected:", socket.id);

  socket.on(
    "register",
    async (data) => await registerHandler(io, socket, data)
  );
  socket.on("groupMessage", async (data) => {
    // const user = await User.findOne({ socketId: socket.id });
    console.log(data);
    const message = new Message({ text: data.msg, type: "group" });
    await message.save();
    console.log("Message :", data.msg, "by", data.user);
    socket.broadcast.emit("gmessage", { message: data.msg, user: data.user });
  });
  socket.on("directMessage", (data) => {
    console.log("Message from client:", data.msg, "for ", data.socketId);
    io.to(data.socketId).emit("dmessage", {
      message: data.msg,
      user: data.user,
    });
  });
  socket.on("requestFile", async (data) => {
    console.log("File request for:", data.fileId);
    const file = await File.findOne({ _id: data.fileId });
    const user = await User.findOne({ ip_address: file.ip });
    console.log("Requesting file from:", user);
    console.log("Requesting file :", file);
    io.to(user.socketId).emit("fileRequest", {
      file: file.path,
      userSocketId: socket.id,
      size : file.size,
    });
  });
  socket.on("portInfo", (data) => {
    io.to(data.userSocketId).emit("free-port", {
      availablePort: data.availablePort,
    });
  });
  socket.on("disconnect", async () => {
    console.log("Client disconnected:", socket.id);
    const user = await User.findOne({ socketId: socket.id });
    if (!user) return;
    socket.broadcast.emit("userDisconnect", { user: user._id });
    console.log("User:", user);
    await File.deleteMany({ owner: user._id });
    await User.deleteOne({ socketId: socket.id });
  });
});

export { server };
