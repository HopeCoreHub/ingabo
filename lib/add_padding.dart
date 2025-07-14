// Padding script using the image package
// 
// To use this script:
// 1. Add the 'image' package to pubspec.yaml:
//    dependencies:
//      image: ^4.0.17
//
// 2. Run the script:
//    dart run lib/add_padding.dart
//
// This will create a padded version of your logo in the assets directory.

import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

void main() async {
  // Path to the original logo
  final String inputPath = 'assets/logo.png';
  // Path for the padded logo
  final String outputPath = 'assets/padded_logo.png';
  
  // Load the original image
  final File inputFile = File(inputPath);
  if (!await inputFile.exists()) {
    print('Error: Input file not found: $inputPath');
    return;
  }
  
  final Uint8List inputBytes = await inputFile.readAsBytes();
  final img.Image? originalImage = img.decodePng(inputBytes);
  
  if (originalImage == null) {
    print('Error: Could not decode the input image');
    return;
  }
  
  // Create a perfect square image (1:1 aspect ratio)
  final int size = 1024; // Create a 1024x1024 image
  
  // Create a new white square image
  final img.Image squareImage = img.Image(width: size, height: size);
  // Fill with white
  img.fill(squareImage, color: img.ColorRgba8(255, 255, 255, 255));
  
  // Calculate scaling to fit the original image within the square while preserving aspect ratio
  final double scale = originalImage.width > originalImage.height
      ? size * 0.6 / originalImage.width    // 60% of width if width is larger
      : size * 0.6 / originalImage.height;  // 60% of height if height is larger
  
  // Calculate new dimensions after scaling
  final int newWidth = (originalImage.width * scale).round();
  final int newHeight = (originalImage.height * scale).round();
  
  // Resize the original image
  final img.Image resizedImage = img.copyResize(
    originalImage,
    width: newWidth,
    height: newHeight,
    interpolation: img.Interpolation.cubic,
  );
  
  // Calculate position to center the image in the square
  final int x = (size - newWidth) ~/ 2;
  final int y = (size - newHeight) ~/ 2;
  
  // Composite the resized image onto the square image
  img.compositeImage(
    squareImage,
    resizedImage,
    dstX: x,
    dstY: y,
  );
  
  // Save the square image
  final File outputFile = File(outputPath);
  await outputFile.writeAsBytes(img.encodePng(squareImage));
  
  print('Successfully created square logo (1:1 aspect ratio) at $outputPath');
} 