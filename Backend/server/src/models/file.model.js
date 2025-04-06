import mongoose, { Schema } from "mongoose";

const fileSchema = new Schema(
  {
    path: {
      type: String,
      required: true,
      trim: true,
    },
    name: {
      type: String,
      required: true,
    },
    owner: {
      type: Schema.Types.ObjectId,
      ref: "User",
    },
    ip: {
      type: String,
      required: true,
    },
    size: {
      type: Number,
    },
    fileType: {
      type: String,
      lowercase: true,
      required: true,
      enum: ["file", "folder"],
    },
  },
  {
    timestamps: true,
  }
);

// fileSchema.pre("save", (next) => {
//   const isValid =
//     path.isAbsolute(this.path) && /^[a-zA-Z0-9_\-/]+$/.test(this.path);

//   if (!isValid) {
//     const err = new Error("Invalid path");
//     return next(err);
//   }
//   return next();
// });

export const File = mongoose.model("File", fileSchema);
