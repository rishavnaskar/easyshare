import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import 'package:path/path.dart';
import 'package:url_launcher/url_launcher.dart';
import 'components/popup_window.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String docID, textInput, senderText, receiverText;
  bool isScanned = false, showSpinner = false;
  File file;
  double progress;
  List<String> filesSent = [];
  List<String> filesReceived = [];
  var _controller = TextEditingController();

  Widget createQR(BuildContext context) {
    return QrImage(
      data: "$docID",
      version: QrVersions.auto,
      size: 0.2 * MediaQuery.of(context).size.height,
    );
  }

  Future<void> createRecord() async {
    final DocumentReference docRef =
        Firestore.instance.collection('records').document();
    setState(() {
      docID = docRef.documentID;
    });
    Firestore.instance
        .collection('records')
        .document('$docID')
        .setData({'docID': '$docID'});
  }

  Future scanQRCode(BuildContext context) async {
    String photoScanResult = await scanner.scan();
    PopUpMessage().neverSatisfied(context, 'Scanned successfully', null);
    Firestore.instance.collection('records').document('$docID').delete();
    setState(() {
      docID = photoScanResult;
      isScanned = true;
    });
  }

  Future<void> uploadFile(BuildContext context) async {
    file = await FilePicker.getFile();
    setState(() {
      showSpinner = true;
    });
    String fileName = basename(file.path);
    final StorageReference storageReference =
        FirebaseStorage().ref().child(fileName);
    final StorageUploadTask uploadTask = storageReference.putFile(file);
    StorageTaskSnapshot taskSnapshot = await uploadTask.onComplete;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();
    StreamBuilder(
      stream: uploadTask.events,
      builder: (context, index) {
        progress = taskSnapshot.bytesTransferred / taskSnapshot.totalByteCount;
        return null;
      },
    );
    final user =
        await Firestore.instance.collection('records').document('$docID').get();
    setState(() {
      if (uploadTask.isComplete && uploadTask.isSuccessful) {
        isScanned
            ? user.reference.updateData({
                'receiverfiles': FieldValue.arrayUnion([downloadUrl])
              })
            : user.reference.updateData({
                'senderfiles': FieldValue.arrayUnion([downloadUrl])
              });
        PopUpMessage().neverSatisfied(context, 'Upload Successful', null);
        showSpinner = false;
      } else if (uploadTask.isCanceled) {
        PopUpMessage().neverSatisfied(context, 'Upload Cancelled', null);
      }
    });
  }

  Future deleteRecord() async {
    textInput = null;
    senderText = null;
    receiverText = null;
    filesSent.clear();
    filesReceived.clear();
    _controller.clear();
    Firestore.instance.collection('records').document('$docID').delete();
    setState(() {
      docID = null;
    });
  }

  Future<void> getFilesSent() async {
    final user =
        await Firestore.instance.collection('records').document('$docID').get();
    if (isScanned == false) {
      if (!filesSent.contains(user.data['senderfiles'].toString()))
        filesSent.add(user.data['senderfiles'].toString());
    } else {
      if (!filesSent.contains(user.data['receiverfiles'].toString()))
        filesSent.add(user.data['receiverfiles'].toString());
    }
  }

  Future<void> getFilesReceived() async {
    final user =
        await Firestore.instance.collection('records').document('$docID').get();
    if (isScanned == false) {
      if (!filesReceived.contains(user.data['receiverfiles'].toString()))
        filesReceived.add(user.data['receiverfiles'].toString());
    } else {
      if (!filesReceived.contains(user.data['senderfiles'].toString()))
        filesReceived.add(user.data['senderfiles'].toString());
    }
  }

  Future deleteFiles() async {
    try {
      getFilesSent();
      getFilesReceived();
      print(filesSent);
      print(filesReceived);
      for (int i = 0; i < filesSent.length; i++) {
        var fileUrlImage = Uri.decodeFull(
            basename(filesSent[i]).replaceAll(new RegExp(r'(\?alt).*'), ''));
        final StorageReference firebaseStorageRefImage =
            FirebaseStorage.instance.ref().child(fileUrlImage);
        await firebaseStorageRefImage.delete();
      }

      for (int i = 0; i < filesReceived.length; i++) {
        var fileUrlImage = Uri.decodeFull(basename(filesReceived[i])
            .replaceAll(new RegExp(r'(\?alt).*'), ''));
        final StorageReference firebaseStorageRefImage =
            FirebaseStorage.instance.ref().child(fileUrlImage);
        await firebaseStorageRefImage.delete();
      }
    } catch (e) {
      print(e);
    }
  }

  void launchURL(String url, BuildContext context) async {
    try {
      await launch(url);
    } catch (e) {
      PopUpMessage().neverSatisfied(context, 'Error downloading', null);
    }
  }

  @override
  void initState() {
    super.initState();
    createRecord();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        deleteRecord();
        return Future.value(true);
      },
      child: ModalProgressHUD(
        inAsyncCall: showSpinner,
        progressIndicator: CircularProgressIndicator(
          backgroundColor: Colors.transparent.withOpacity(0.6),
          value: progress,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
        child: Scaffold(
          resizeToAvoidBottomPadding: false,
          backgroundColor: Colors.white.withOpacity(0.9),
          body: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: <Widget>[
                Container(
                  height: isScanned
                      ? 0.9 * MediaQuery.of(context).size.height
                      : 0.7 * MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.vertical(bottom: Radius.circular(25.0)),
                      boxShadow: [BoxShadow(blurRadius: 50.0)],
                      image: DecorationImage(
                        image: AssetImage('assets/image2.jpg'),
                        fit: BoxFit.cover,
                      )),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Flexible(
                          child: SizedBox(
                              height:
                                  0.04 * MediaQuery.of(context).size.height)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          IconButton(
                            padding: EdgeInsets.only(left: 15.0),
                            icon: Icon(Icons.settings_overscan),
                            color: Colors.transparent.withOpacity(0.8),
                            onPressed: () => scanQRCode(context),
                            iconSize: 25.0,
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.attach_file),
                            color: Colors.transparent.withOpacity(0.8),
                            onPressed: () {
                              uploadFile(context);
                            },
                            iconSize: 25.0,
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline),
                            color: Colors.transparent.withOpacity(0.8),
                            onPressed: () {
                              deleteFiles().whenComplete(() {
                                deleteRecord();
                                createRecord();
                              });
                              setState(() {
                                isScanned = false;
                              });
                            },
                            iconSize: 25.0,
                          ),
                        ],
                      ),
                      docID == null
                          ? Padding(
                              padding: EdgeInsets.only(right: 15.0),
                              child: Text(
                                'Creating...',
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                          : Padding(
                              padding: EdgeInsets.only(right: 15.0),
                              child: Text('Unique ID - $docID',
                                  style: TextStyle(color: Colors.white)),
                            ),
                      Expanded(
                        flex: 10,
                        child: Container(
                            padding: EdgeInsets.fromLTRB(15.0, 5.0, 15.0, 5.0),
                            child: TextField(
                              controller: _controller,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                              decoration: InputDecoration(
                                  border: InputBorder.none,
                                  filled: true,
                                  fillColor: Colors.transparent.withOpacity(0.6),
                                  hintText: 'Type here...',
                                  hintStyle: TextStyle(color: Colors.white),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(20.0)),
                                      borderSide: BorderSide(
                                          color: Colors.white,
                                          style: BorderStyle.solid,
                                          width: 2.0)),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(20.0)),
                                      borderSide: BorderSide(
                                          color: Colors.white,
                                          style: BorderStyle.solid,
                                          width: 2.0))),
                              onChanged: (value) {
                                setState(() {
                                  textInput = value;
                                  if (isScanned == true) {
                                    Firestore.instance
                                        .collection('records')
                                        .document('$docID')
                                        .updateData(
                                            {'receivertext': textInput});
                                  } else {
                                    Firestore.instance
                                        .collection('records')
                                        .document('$docID')
                                        .updateData({'sendertext': textInput});
                                  }
                                });
                              },
                            )),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 2.5, horizontal: 15.0),
                        child: Row(
                          children: <Widget>[
                            RaisedButton(
                              elevation: 20.0,
                              child: Text('Files Sent',
                                  style: TextStyle(color: Colors.white)),
                              onPressed: () async {
                                getFilesSent();
                                if (filesSent.contains(null))
                                  filesSent.removeWhere(null);
                                PopUpMessage().neverSatisfied(
                                  context,
                                  'Files Sent',
                                  ListView.builder(
                                    itemCount: filesSent.length,
                                    itemBuilder: (context, index) {
                                      String temp = filesSent[index]
                                          .toString()
                                          .replaceAll('[', '')
                                          .replaceAll(']', '');
                                      return ListTile(
                                        title: Text('$temp'),
                                        onTap: () =>
                                            launchURL('$temp', context),
                                      );
                                    },
                                  ),
                                );
                              },
                              color: Colors.transparent.withOpacity(0.6),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10.0))),
                            ),
                            Spacer(),
                            RaisedButton(
                              elevation: 20.0,
                              child: Text('Files Received',
                                  style: TextStyle(color: Colors.white)),
                              onPressed: () async {
                                getFilesReceived();
                                if (filesReceived.contains(null))
                                  filesReceived.removeWhere(null);
                                PopUpMessage().neverSatisfied(
                                  context,
                                  'Files Sent',
                                  ListView.builder(
                                    itemCount: filesReceived.length,
                                    itemBuilder: (context, index) {
                                      String temp = filesReceived[index]
                                          .toString()
                                          .replaceAll('[', '')
                                          .replaceAll(']', '');
                                      return ListTile(
                                        title: Text('$temp'),
                                        onTap: () =>
                                            launchURL('$temp', context),
                                      );
                                    },
                                  ),
                                );
                              },
                              color: Colors.transparent.withOpacity(0.6),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10.0))),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 10,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: Firestore.instance
                              .collection('records')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Center(
                                  child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ));
                            } else {
                              final users = snapshot.data.documents;
                              for (var user in users) {
                                if (user.documentID == docID) {
                                  isScanned
                                      ? senderText = user.data['sendertext']
                                      : receiverText =
                                          user.data['receivertext'];
                                }
                              }
                              return Padding(
                                padding:
                                    EdgeInsets.fromLTRB(15.0, 5.0, 15.0, 0.0),
                                child: Container(
                                  padding: EdgeInsets.all(10.0),
                                  height: 200,
                                  alignment: Alignment.topLeft,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent.withOpacity(0.6),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(20.0)),
                                    border: Border.all(
                                        color: Colors.white,
                                        style: BorderStyle.solid,
                                        width: 2.0),
                                  ),
                                  child: isScanned
                                      ? (senderText == null
                                          ? Text('Text will appear here',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold))
                                          : SelectableText('$senderText',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold)))
                                      : (receiverText == null
                                          ? Text('Text will appear here',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold))
                                          : SelectableText('$receiverText',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight:
                                                      FontWeight.bold))),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      SizedBox(height: 10.0),
                    ],
                  ),
                ),
                Flexible(child: SizedBox(height: 40.0)),
                isScanned ? Container() : createQR(context),
                Flexible(child: SizedBox(height: 10.0)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
