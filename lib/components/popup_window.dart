import 'package:flutter/material.dart';

class PopUpMessage {

  Future<void> neverSatisfied(BuildContext context, String text, Widget content) async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('$text', style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.white,
            elevation: 20.0,
            content: content,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0)),
            ),
            actions: <Widget>[
              RaisedButton(
                child: Text('Ok', style: TextStyle(color: Colors.black)),
                color: Colors.white,
                onPressed: () => Navigator.pop(context),
              )
            ],
          );
        });
  }
}