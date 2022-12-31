import 'package:farmr_dashboard/constants.dart';
import 'package:farmr_dashboard/screens/modals/modal_screen.dart';
import 'package:flutter/material.dart';
import 'package:after_layout/after_layout.dart';

class HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTapFunction;
  final Color? color;
  final String title;

  HeaderButton(
      {required this.icon,
      required this.onTapFunction,
      required this.color,
      required this.title});

  Widget build(BuildContext context) {
    return Tooltip(
        waitDuration: Duration(seconds: 1),
        message: title,
        child: Material(
            color: color,
            animationDuration: animationDuration,
            borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
            child: InkWell(
              borderRadius:
                  const BorderRadius.all(Radius.circular(borderRadius)),
              onTap: onTapFunction,
              child: Padding(
                  padding: EdgeInsets.all(defaultPadding * 0.5),
                  child: IntrinsicHeight(
                      child: AspectRatio(
                          aspectRatio: 1,
                          child: Icon(
                            icon,
                            size: 24,
                            color: Theme.of(context).textTheme.bodyText1!.color,
                          )))),
            )));
  }
}

class ModalButton extends StatefulWidget {
  const ModalButton(
      {Key? key,
      required this.icon,
      required this.child,
      required this.windowTitle,
      this.blink = false,
      this.modalWidth = 500})
      : super(key: key);
  final IconData icon;
  final Widget child;
  final String windowTitle;
  final double modalWidth;
  final bool blink;

  @override
  _ModalButtonState createState() => _ModalButtonState();
}

class _ModalButtonState extends State<ModalButton>
    with SingleTickerProviderStateMixin, AfterLayoutMixin<ModalButton> {
  bool portalVisible = false;

  AnimationController? _colorAnimationController;
  Animation<Color?>? _colorTween;
  bool prevBlink = false;

  @override
  void initState() {
    _colorAnimationController =
        AnimationController(vsync: this, duration: Duration(seconds: 2));

    _colorAnimationController!.addListener(() {
      setState(() {});
    });

    super.initState();
  }

  void afterFirstLayout(BuildContext context) {
    print(widget.blink);

    _colorTween = ColorTween(
            begin: Theme.of(context).canvasColor,
            end: Theme.of(context).accentColor)
        .animate(CurvedAnimation(
            parent: _colorAnimationController!, curve: Curves.easeInOut));

    if (widget.blink) _colorAnimationController!.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.blink && widget.blink != prevBlink) {
      _colorAnimationController!.repeat(reverse: true);
      prevBlink = widget.blink;
    } else if (!widget.blink && widget.blink != prevBlink) {
      _colorAnimationController!.reverse();
      prevBlink = widget.blink;
    }

    return Hero(
      tag: widget.windowTitle,
      child: HeaderButton(
        title: widget.windowTitle,
        color: (!widget.blink)
            ? Theme.of(context).canvasColor
            : _colorTween?.value,
        onTapFunction: () {
          Navigator.of(context).push(PageRouteBuilder(
              opaque: false,
              transitionDuration: slowAnimationDuration,
              transitionsBuilder:
                  (context, animation, anotherAnimation, child) {
                animation =
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut);
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              pageBuilder: (BuildContext context, _, __) {
                return ModalScreen(
                  heroTag: widget.windowTitle,
                  child: widget.child,
                  windowTitle: widget.windowTitle,
                  updateFunction: () {},
                );
              }));
        },
        icon: widget.icon,
      ),
    );
  }
}
