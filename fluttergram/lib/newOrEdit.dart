import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttergram/shared.dart';

import 'package:http/http.dart' as http;

Dio dio = new Dio();

class NewOrEditPost extends StatefulWidget {
  final Data appData;
  final bool isNew;
  //is new == true
  final File newImage;
  //is new == false
  final String imageUrl;
  final int postID;
  final String caption;

  NewOrEditPost({
    this.appData,
    this.isNew,
    this.newImage,
    this.imageUrl,
    this.postID,
    this.caption,
  });

  _NewOrEditPostState createState() => _NewOrEditPostState();
}

class _NewOrEditPostState extends State<NewOrEditPost> {
  TextEditingController captionText = new TextEditingController();

  @override
  void initState() { 
    super.initState();
    if(widget.isNew == false){
      captionText.text = widget.caption;
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: PreferredSize(
        //The TopBar Widget will handel the size
        preferredSize: Size.fromHeight(45),
        child: TopBar(
          leading: (widget.isNew) ? BackButton() : CloseButton(),
          title: new Text((widget.isNew) ? "New Post" : "Edit Info"),
          trailing: (widget.isNew)
          ? new FlatButton(
            onPressed: () => submitNewPost(),
            child: new Text(
              "Share",
              style: TextStyle(
                color: Colors.blue,
              ),
            ),
          )
          : new IconButton(
            onPressed: () => editPost(),
            icon: Icon(
              Icons.check,
              color: Colors.blue
            ),
          ),
        ),
      ),
      body: ListView(
        children: <Widget>[
          Container(
            height: width,
            width: width,
            decoration: BoxDecoration(
              image: new DecorationImage(
                image: (widget.isNew) 
                ? FileImage(widget.newImage)
                : FadeInImage(
                  fit: BoxFit.cover,
                  placeholder: const AssetImage('assets/imagePlaceholder.png'),
                  image: new NetworkImage(
                    widget.imageUrl,
                  ),
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: new TextFormField(
              autofocus: true,
              controller: captionText,
              maxLines: 5,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.all(8),
                hintText: "Type Your Caption",
              ),
            ),
          ),
        ],
      ),
    );
  }

  void editPost() async{
    //retreive data from server
    var urlMod = widget.appData.url + "/api/v1/posts/" + widget.postID.toString();
    urlMod += "?caption=" + captionText.text;

    return await http.patch(
      urlMod, 
      headers: {HttpHeaders.authorizationHeader: "Bearer " + widget.appData.token}
    ).then((response){
      if(response.statusCode == 200){
        print("update post success");
        Navigator.of(context).pop();
        //TODO... get the count of user posts... user likes... and user comments
      }
      else{ 
        print(urlMod + " update post fail");
        //TODO... trigger some visual error
      }
    });
  }

  void submitNewPost() async{
    //localhost:4567/api/v1/posts
    
    //pop the new or edit page
    Navigator.of(context).pop();

    var urlMod = widget.appData.url + "/api/v1/posts";

    FormData formData = new FormData.from({
      "token": widget.appData.token,
      "image": new UploadFileInfo(widget.newImage, "img.jpeg"),
      "caption": captionText.text,
    });

    var response = await dio.post(
      urlMod, 
      options: Options(
        method: "POST",
        headers: {HttpHeaders.authorizationHeader: "Bearer " + widget.appData.token},
      ),
      data: formData,
    );

    print("*************************RELOAD THE PAGE");
  }
}