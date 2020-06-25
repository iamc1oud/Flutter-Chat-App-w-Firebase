import 'package:flutter/material.dart';
import 'const.dart';

class Loading extends StatelessWidget {
  const Loading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: 100,
      child: Center(
        child: Image(
          image: NetworkImage("images/loadergif.gif"),
        ),
      ),
      color: Colors.white.withOpacity(0.8),
    );
  }
}
