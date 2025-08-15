import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data_performance_provider.dart';

class PerformanceUtils {
  // Get image quality based on low data mode setting
  static double getImageQuality(BuildContext context) {
    final dataPerformanceProvider = Provider.of<DataPerformanceProvider>(context, listen: false);
    return dataPerformanceProvider.lowDataMode ? 0.5 : 1.0;
  }
  
  // Get cache height based on low data mode setting
  static int? getCacheHeight(BuildContext context) {
    final dataPerformanceProvider = Provider.of<DataPerformanceProvider>(context, listen: false);
    return dataPerformanceProvider.lowDataMode ? 300 : null;
  }
  
  // Get cache width based on low data mode setting
  static int? getCacheWidth(BuildContext context) {
    final dataPerformanceProvider = Provider.of<DataPerformanceProvider>(context, listen: false);
    return dataPerformanceProvider.lowDataMode ? 300 : null;
  }
  
  // Check if image lazy loading is enabled
  static bool isImageLazyLoadingEnabled(BuildContext context) {
    final dataPerformanceProvider = Provider.of<DataPerformanceProvider>(context, listen: false);
    return dataPerformanceProvider.imageLazyLoading;
  }
  
  // Check if offline mode is enabled
  static bool isOfflineModeEnabled(BuildContext context) {
    final dataPerformanceProvider = Provider.of<DataPerformanceProvider>(context, listen: false);
    return dataPerformanceProvider.offlineMode;
  }
  
  // Get network image with performance settings applied
  static Widget getNetworkImage({
    required BuildContext context,
    required String imageUrl,
    double? width,
    double? height,
    BoxFit? fit,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    final dataPerformanceProvider = Provider.of<DataPerformanceProvider>(context, listen: false);
    final lowDataMode = dataPerformanceProvider.lowDataMode;
    final imageLazyLoading = dataPerformanceProvider.imageLazyLoading;
    
    // Default placeholder
    final defaultPlaceholder = Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.image,
          color: Colors.grey.shade400,
          size: 24,
        ),
      ),
    );
    
    // Default error widget
    final defaultErrorWidget = Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey.shade400,
          size: 24,
        ),
      ),
    );
    
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      cacheHeight: lowDataMode ? 300 : null,
      cacheWidth: lowDataMode ? 300 : null,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return placeholder ?? defaultPlaceholder;
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? defaultErrorWidget;
      },
      frameBuilder: imageLazyLoading 
        ? (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) {
              return child;
            }
            return placeholder ?? defaultPlaceholder;
          }
        : null,
    );
  }
} 