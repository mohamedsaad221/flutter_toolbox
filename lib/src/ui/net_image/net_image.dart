import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_toolbox/flutter_toolbox.dart';
import 'package:photo_view/photo_view.dart';

import 'extensions.dart';

const imageResizerUl = 'https://images.weserv.nl/?url=';

class NetImage extends StatefulWidget {
  const NetImage(
    this.imageUrl, {
    Key? key,
    this.imageBuilder,
    this.placeholder,
    this.errorWidget,
    this.fadeOutDuration: const Duration(milliseconds: 300),
    this.fadeOutCurve: Curves.easeOut,
    this.fadeInDuration: const Duration(milliseconds: 700),
    this.fadeInCurve: Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment: Alignment.center,
    this.repeat: ImageRepeat.noRepeat,
    this.matchTextDirection = false,
    this.httpHeaders,
    this.cacheManager,
    this.useOldImageOnUrlChange = false,
    this.color,
    this.colorBlendMode,
    this.fullScreen = false,
    this.hero = false,
    this.borderRadius,
    this.onTap,
  });

  /// Option to use cachemanager with other settings
  final BaseCacheManager? cacheManager;

  /// The target image that is displayed.
  final String imageUrl;

  /// Optional builder to further customize the display of the image.
  final ImageWidgetBuilder? imageBuilder;

  /// Widget displayed while the target [imageUrl] is loading.
  final PlaceholderWidgetBuilder? placeholder;

  /// Widget displayed while the target [imageUrl] failed loading.
  final LoadingErrorWidgetBuilder? errorWidget;

  /// The duration of the fade-out animation for the [placeholder].
  final Duration fadeOutDuration;

  /// The curve of the fade-out animation for the [placeholder].
  final Curve fadeOutCurve;

  /// The duration of the fade-in animation for the [imageUrl].
  final Duration fadeInDuration;

  /// The curve of the fade-in animation for the [imageUrl].
  final Curve fadeInCurve;

  /// If non-null, require the image to have this width.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio. This may result in a sudden change if the size of the
  /// placeholder widget does not match that of the target image. The size is
  /// also affected by the scale factor.
  final double? width;

  /// If non-null, require the image to have this height.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio. This may result in a sudden change if the size of the
  /// placeholder widget does not match that of the target image. The size is
  /// also affected by the scale factor.
  final double? height;

  /// How to inscribe the image into the space allocated during layout.
  ///
  /// The default varies based on the other fields. See the discussion at
  /// [paintImage].
  final BoxFit? fit;

  /// How to align the image within its bounds.
  ///
  /// The alignment aligns the given position in the image to the given position
  /// in the layout bounds. For example, a [Alignment] alignment of (-1.0,
  /// -1.0) aligns the image to the top-left corner of its layout bounds, while a
  /// [Alignment] alignment of (1.0, 1.0) aligns the bottom right of the
  /// image with the bottom right corner of its layout bounds. Similarly, an
  /// alignment of (0.0, 1.0) aligns the bottom middle of the image with the
  /// middle of the bottom edge of its layout bounds.
  ///
  /// If the [alignment] is [TextDirection]-dependent (i.e. if it is a
  /// [AlignmentDirectional]), then an ambient [Directionality] widget
  /// must be in scope.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// How to paint any portions of the layout bounds not covered by the image.
  final ImageRepeat repeat;

  /// Whether to paint the image in the direction of the [TextDirection].
  ///
  /// If this is true, then in [TextDirection.ltr] contexts, the image will be
  /// drawn with its origin in the top left (the "normal" painting direction for
  /// children); and in [TextDirection.rtl] contexts, the image will be drawn with
  /// a scaling factor of -1 in the horizontal direction so that the origin is
  /// in the top right.
  ///
  /// This is occasionally used with children in right-to-left environments, for
  /// children that were designed for left-to-right locales. Be careful, when
  /// using this, to not flip children with integral shadows, text, or other
  /// effects that will look incorrect when flipped.
  ///
  /// If this is true, there must be an ambient [Directionality] widget in
  /// scope.
  final bool matchTextDirection;

  // Optional headers for the http request of the image url
  final Map<String, String>? httpHeaders;

  /// When set to true it will animate from the old image to the new image
  /// if the url changes.
  final bool useOldImageOnUrlChange;

  /// If non-null, this color is blended with each image pixel using [colorBlendMode].
  final Color? color;

  /// Used to combine [color] with this image.
  ///
  /// The default is [BlendMode.srcIn]. In terms of the blend mode, [color] is
  /// the source and this image is the destination.
  ///
  /// See also:
  ///
  ///  * [BlendMode], which includes an illustration of the effect of each blend mode.
  final BlendMode? colorBlendMode;

  /// default false.
  final bool fullScreen;

  /// Adds hero animation, uses the url as the hero tag.
  /// [fullScreen] needs to be true for this to work.
  /// default false.
  final bool hero;

  /// defaults to 0
  final BorderRadius? borderRadius;

  /// Called when the user taps this part of the image.
  final GestureTapCallback? onTap;

  @override
  _NetImageState createState() => _NetImageState();
}

class _NetImageState extends State<NetImage> {
  Future _openFullScreen(BuildContext context) {
    return push(context, FullScreenImage(widget.imageUrl), authCheck: false);
  }

  String _getFormattedUrl(String originalImageUrl, BoxConstraints constraints) {
    if (originalImageUrl.isNotEmpty != true) return '';

    final imageUrl = '$imageResizerUl$originalImageUrl';

    int? width;
    int? height;
    if (constraints.maxWidth != double.infinity) {
      width = constraints.maxWidth.toInt();
    }
    if (constraints.maxHeight != double.infinity) {
      height = constraints.maxHeight.toInt();
    }
    return imageUrl.getSizedFormattedUrl(context, width: width, height: height);
  }

  @override
  Widget build(BuildContext context) {
    final toolboxConfig = ToolboxConfig.of(context, listen: false);

    if (toolboxConfig.useWeservResizer != true) return _image(widget.imageUrl);

    return LayoutBuilder(
      builder: (ctx, constraints) {
        if (widget.width != null || widget.height != null) {
          constraints = BoxConstraints(
            maxWidth: widget.width ?? double.minPositive,
            maxHeight: widget.height ?? double.minPositive,
          );
        }

        final url = _getFormattedUrl(widget.imageUrl, constraints);
        if (toolboxConfig.logLoadedImageUrl) print(url);
        return _image(url);
      },
    );
  }

  Widget _image(String url) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(0),
        child: Stack(
          children: <Widget>[
            widget.fullScreen && widget.hero
                ? Hero(
                    tag: widget.imageUrl,
                    child: _cachedNetworkImage(url),
                  )
                : _cachedNetworkImage(url),
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: widget.onTap != null
                      ? widget.onTap
                      : widget.fullScreen
                          ? () => _openFullScreen(context)
                          : () => null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cachedNetworkImage(String? imageUrl) {

    return CachedNetworkImage(
      imageUrl: imageUrl ?? '',
      placeholder: widget.placeholder ??
          (_, __) => Center(child: CircularProgressIndicator()),
      errorWidget: (context,name,error) => Icon(Icons.error),
      imageBuilder: widget.imageBuilder,
      fadeOutDuration: widget.fadeOutDuration,
      fadeOutCurve: widget.fadeOutCurve,
      fadeInDuration: widget.fadeInDuration,
      fadeInCurve: widget.fadeInCurve,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment as Alignment,
      repeat: widget.repeat,
      matchTextDirection: widget.matchTextDirection,
      httpHeaders: widget.httpHeaders,
      cacheManager: widget.cacheManager,
      useOldImageOnUrlChange: widget.useOldImageOnUrlChange,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      key: widget.key,
    );
  }
}

class FullScreenImage extends StatelessWidget {
  FullScreenImage(this.imageUrl);

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(imageUrl),
      direction: DismissDirection.vertical,
      onDismissed: (direction) => Navigator.of(context).pop(),
      child: Dismissible(
        key: Key(imageUrl),
        onDismissed: (direction) => Navigator.of(context).pop(),
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            leading: CloseButton(),
          ),
          backgroundColor: Colors.black,
          body: PhotoView(
            imageProvider: NetworkImage(imageUrl),
            heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
          ),
        ),
      ),
    );
  }
}
