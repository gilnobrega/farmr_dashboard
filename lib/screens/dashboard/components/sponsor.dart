import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:farmr_dashboard/constants.dart';

class MenuFooterSponsor extends StatefulWidget {
  MenuFooterSponsor(
      {required this.url,
      required this.name,
      required this.imgUrl,
      this.card = false});
  final String name;
  final String url;
  final bool card;
  final String imgUrl;

  MenuFooterSponsorState createState() => MenuFooterSponsorState();
}

class MenuFooterSponsorState extends State<MenuFooterSponsor>
    with SingleTickerProviderStateMixin {
  void _launchURL() async => await canLaunch(widget.url)
      ? await launch(widget.url)
      : throw 'Could not launch ${widget.url}';

  late AnimationController _animationController;
  late Animation<double> _animation;
  late Image imageSource;
  double elevation = 0;
  double scale = 1.0;

  @override
  void initState() {
    super.initState();

    imageSource = Image.network(widget.imgUrl,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        fit: BoxFit.cover);

    Future.delayed(Duration(seconds: 0), () {
      precacheImage(imageSource.image, context);
    });

    _animationController = AnimationController(
      duration: animationDuration,
      vsync: this,
    );
    _animation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _animation.addListener(() {
      setState(() {
        scale = (!widget.card) ? 1.0 + (0.1 * _animation.value) : 1.0;
        elevation = _animation.value * 8;
      });
    });
  }

  Widget build(BuildContext context) {
    var image = ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
      child: imageSource,
    );

    var imageContainer = Material(
        borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
        elevation: elevation,
        child: Stack(
          children: [
            (widget.card) ? Positioned.fill(child: image) : image,
            Positioned.fill(
              child: Container(
                //padding: EdgeInsets.all(defaultPadding),
                child: Material(
                    borderRadius:
                        BorderRadius.all(Radius.circular(borderRadius)),
                    color: Colors.transparent,
                    child: InkWell(
                      onHover: (value) {
                        if (value)
                          _animationController.forward();
                        else
                          _animationController.reverse();
                      },
                      borderRadius:
                          BorderRadius.all(Radius.circular(borderRadius)),
                      onTap: _launchURL,
                    )),
              ),
            )
          ],
        ));
    return Transform.scale(
      scale: scale,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.card)
            Padding(
                padding: EdgeInsets.only(bottom: defaultPadding / 4),
                child: Text(
                  "Sponsored by " + widget.name,
                  textAlign: TextAlign.left,
                  style: Theme.of(context)
                      .textTheme
                      .caption
                      ?.copyWith(fontSize: 9),
                )),
          (widget.card) ? Expanded(child: imageContainer) : imageContainer,
        ],
      ),
    );
  }
}
