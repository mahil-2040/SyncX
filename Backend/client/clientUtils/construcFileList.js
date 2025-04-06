import fs from "fs";
import path from "path";

const getFolderContents = (folderPath) => {
  const results = [];
  const files = fs.readdirSync(folderPath);

  files.forEach((file) => {
    const fullPath = path.join(folderPath, file);
    const stats = fs.statSync(fullPath);

    if (stats.isDirectory()) {
      results.push({
        name: file,
        path: fullPath,
        type: "folder",
      });
      results.push(...getFolderContents(fullPath));
    } else {
      results.push({
        name: file,
        path: fullPath,
        type: "file",
        size: stats.size, // File size in bytes
      });
    }
  });

  return results;
};

export { getFolderContents };
