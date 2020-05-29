import 'package:easyshare/home_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/image1.jpg'),
            fit: BoxFit.cover,
          )
        ),
        child: Padding(
          padding: EdgeInsets.only(left: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 0.13 * MediaQuery.of(context).size.height),
              Text('Easy Share', style: TextStyle(
                color: Colors.white,
                fontSize: 50.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSans',
                shadows: [BoxShadow(blurRadius: 25.0, offset: Offset(10.0, 10.0))]
              )),
              Flexible(child: SizedBox(height: 20)),
              Text('Now share stuff with your friends in realtime', style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 18.0,
                fontFamily: 'NotoSans',
              )),
              Flexible(child: SizedBox(height: 0.2 * MediaQuery.of(context).size.height)),
              RaisedButton(
                color: Colors.white,
                elevation: 20.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
                child: Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Text('Get Started', style: TextStyle(
                    color: Color(0xffd32f2f),
                    fontSize: 25.0,
                  )),
                ),
                onPressed: () => Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => HomePage())),
              ),
            ],
          ),
        )
      ),
    );
  }
}
