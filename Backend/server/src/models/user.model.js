import mongoose, { Schema } from "mongoose";

const ipValidator = (ip) => {
  return /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/.test(
    ip
  );
};

const userSchema = new Schema(
  {
    username: {
      type: String,
      required: true,
      lowercase: true,
      unique: true,
      trim: true,
    },
    ip_address: {
      type: String,
      required: true,
      trim: true,
      validate: {
        validator: ipValidator,
        message: () => "Not a valid ip",
      },
    },
    lastActive: {
      type: Schema.Types.Date,
      sparse: true,
      default: null,
    },
    status: {
      type: String,
      enum: ["online", "offline"],
      default: "online",
    },
    socketId: {
      type: String,
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

export const User = mongoose.model("User", userSchema);
