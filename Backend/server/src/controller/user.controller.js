import { File } from "../models/file.model.js";
import { User } from "../models/user.model.js";
import { Message } from "../models/message.model.js";
import { ApiError } from "../utils/ApiError.js";
import { asyncHandler } from "../utils/asyncHandler.js";

const getGroupMessages = asyncHandler(async (req, res) => {
  try {
    const messages = await Message.find({ type: "group" }).populate("owner");
    res.status(200).json(messages);
  } catch (error) {
    throw new ApiError(500, "Internal Server Error");
  }
});

const getDirectMessages = asyncHandler(async (req, res) => {
  const { userId } = req.params;
  if (!userId || !req.user._id || userId === req.user._id) {
    throw new ApiError(400, "User Id is required");
  }
  try {
    const messages = await Message.find({
      type: "direct",
      $or: [{ $and: [{ owner: req.user._id }, { for: userId }] }, { $and: [{ owner: userId }, { for: req.user._id }] }]
    }).populate("owner", "for");
    res.status(200).json(messages);
  } catch (error) {
    throw new ApiError(
      error.statusCode || 500,
      error.message || "Internal Server Error"
    );
  }
});

const getUsers = asyncHandler(async (req, res) => {
  try {
    const users = await User.find();
    res.status(200).json(users);
  } catch (error) {
    throw new ApiError(500, "Internal Server Error");
  }
});

const getFiles =  asyncHandler(async (req, res) => {
  const { owner } = req.params;
  if (!owner) {
    throw new ApiError(400, "Owner is required");
  }
  try {
    const files = await File.find({ owner });
    res.status(200).json(files);
  } catch (error) {
    throw new ApiError(500, "Internal Server Error");
  }
});

const requestFileIp = asyncHandler(async (req, res) => {
  const { fileId } = req.params;
  if (!fileId) {
    throw new ApiError(400, "File Id is required");
  }
  try {
    const file = await File.findById(fileId);
    if (!file) {
      throw new ApiError(404, "File not found");
    }
    
    res.status(200).json({ ip : file.ip });
  } catch (error) {
    throw new ApiError(
      error.statusCode || 500,
      error.message || "Internal Server Error"
    );
  }
});

const searchFile = asyncHandler(async (req, res) => {
  const { squery } = req.params;
  if (!squery) {
    throw new ApiError(400, "File Name is required");
  }
  try {
    const files = await File.find({
      $and :[
        { name: { $regex: squery, $options: "i" } },
        { fileType: "file" }
      ]
    });
    res.status(200).json(files);
  } catch (error) {
    throw new ApiError(
      error.statusCode || 500,
      error.message || "Internal Server Error"
    );
  }
});

export { getGroupMessages, getDirectMessages, getUsers, getFiles, requestFileIp, searchFile };
