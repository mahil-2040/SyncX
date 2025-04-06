import mongoose, { Schema } from "mongoose";

const messageSchema = new Schema(
  {
    text: {
      type: String,
      required: true,
    },
    owner: {
      type: Schema.Types.ObjectId,
      ref: "User",
    },
    type: {
      type: String,
      lowercase: true,
      enum: ["group", "direct"],
      required: true,
    },
    for: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: function () {
        return this.type === "direct";
      },
    },
  },
  {
    timestamps: true,
  }
);

export const Message = mongoose.model("Message", messageSchema);
