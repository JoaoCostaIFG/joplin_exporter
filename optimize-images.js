#!/usr/bin/env node
/**
 * Optimize images in a directory using Sharp.
 *
 * Usage: node optimize-images.js <directory>
 *
 * Optimizes PNG and JPEG images in-place, skipping animated images.
 */

const fs = require("fs");
const path = require("path");
const sharp = require("sharp");

// Quality settings
const PNG_QUALITY = 90;
const PNG_COMPRESSION = 9;
const JPEG_QUALITY = 85;

// Supported extensions
const IMAGE_EXTENSIONS = [".png", ".jpg", ".jpeg", ".webp"];

function logInfo(message) {
  console.log(`[INFO] ${new Date().toISOString()} ${message}`);
}

function logError(message) {
  console.error(`[ERROR] ${new Date().toISOString()} ${message}`);
}

function formatBytes(bytes) {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
}

async function isAnimated(filePath) {
  try {
    const metadata = await sharp(filePath).metadata();
    return (metadata.pages || 1) > 1;
  } catch (error) {
    logError(
      `Failed to check animation for ${path.basename(filePath)}: ${error.message}`,
    );
    return false;
  }
}

function getFileSize(filePath) {
  try {
    return fs.statSync(filePath).size;
  } catch {
    return 0;
  }
}

async function optimizeImage(filePath) {
  const filename = path.basename(filePath);
  const ext = path.extname(filePath).toLowerCase();

  try {
    // Check if animated
    const animated = await isAnimated(filePath);
    if (animated) {
      logInfo(`  ⊘ ${filename} (animated, skipped)`);
      return { result: "skipped", sizeBefore: 0, sizeAfter: 0 };
    }

    const sizeBefore = getFileSize(filePath);
    const tempPath = filePath + ".tmp";

    // Optimize based on format
    if (ext === ".png") {
      await sharp(filePath)
        .png({ quality: PNG_QUALITY, compressionLevel: PNG_COMPRESSION })
        .toFile(tempPath);
    } else if (ext === ".jpg" || ext === ".jpeg") {
      await sharp(filePath).jpeg({ quality: JPEG_QUALITY }).toFile(tempPath);
    } else {
      // For other formats, skip
      logInfo(`  ⊘ ${filename} (unsupported format, skipped)`);
      return { result: "skipped", sizeBefore: 0, sizeAfter: 0 };
    }

    // Replace original with optimized version
    fs.renameSync(tempPath, filePath);

    const sizeAfter = getFileSize(filePath);
    const savings = sizeBefore - sizeAfter;
    const savingsPercent = ((savings / sizeBefore) * 100).toFixed(1);

    logInfo(
      `  ✓ ${filename} (${formatBytes(sizeBefore)} → ${formatBytes(sizeAfter)}, -${savingsPercent}%)`,
    );

    return { result: "optimized", sizeBefore, sizeAfter };
  } catch (error) {
    logError(`  ✗ ${filename}: ${error.message}`);
    return { result: "error", sizeBefore: 0, sizeAfter: 0 };
  }
}

function getImageFiles(directory) {
  if (!fs.existsSync(directory)) {
    logError(`Directory not found: ${directory}`);
    return [];
  }

  const files = fs.readdirSync(directory);
  return files
    .filter((file) => {
      const ext = path.extname(file).toLowerCase();
      return IMAGE_EXTENSIONS.includes(ext);
    })
    .map((file) => path.join(directory, file))
    .sort();
}

async function main() {
  const args = process.argv.slice(2);

  if (args.length !== 1) {
    console.error("Usage: node optimize-images.js <directory>");
    process.exit(1);
  }

  const directory = args[0];

  logInfo("Optimizing images...");
  logInfo(`Directory: ${directory}`);

  const imageFiles = getImageFiles(directory);

  if (imageFiles.length === 0) {
    logInfo("No images found to optimize.");
    return;
  }

  const stats = {
    optimized: 0,
    skipped: 0,
    errors: 0,
    totalSizeBefore: 0,
    totalSizeAfter: 0,
  };

  // Process each image
  for (const filePath of imageFiles) {
    const { result, sizeBefore, sizeAfter } = await optimizeImage(filePath);

    if (result === "optimized") {
      stats.optimized++;
      stats.totalSizeBefore += sizeBefore;
      stats.totalSizeAfter += sizeAfter;
    } else if (result === "skipped") {
      stats.skipped++;
    } else {
      stats.errors++;
    }
  }

  // Summary
  const totalSavings = stats.totalSizeBefore - stats.totalSizeAfter;
  const totalSavingsPercent =
    stats.totalSizeBefore > 0
      ? ((totalSavings / stats.totalSizeBefore) * 100).toFixed(1)
      : "0.0";

  logInfo("");
  logInfo(
    `Done! Optimized ${stats.optimized}, skipped ${stats.skipped}${stats.errors > 0 ? `, errors ${stats.errors}` : ""}`,
  );

  if (stats.totalSizeBefore > 0) {
    logInfo(
      `Total savings: ${formatBytes(totalSavings)} (-${totalSavingsPercent}%)`,
    );
  }

  if (stats.errors > 0) {
    process.exit(1);
  }
}

main().catch((error) => {
  logError(`Fatal error: ${error.message}`);
  process.exit(1);
});
