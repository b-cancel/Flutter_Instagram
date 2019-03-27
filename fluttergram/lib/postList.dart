import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttergram/comments.dart';
import 'package:fluttergram/main.dart';
import 'package:fluttergram/profile.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'dart:convert';
import 'package:async/async.dart';
import 'package:http/http.dart' as http;

class PostList extends StatefulWidget {
  final Data appData;
  final Function callback;

  PostList({
    Key key,
    this.appData,
    @required this.callback,
  }) : super(key: key);

  @override
  _PostListState createState() => _PostListState();
}

class _PostListState extends State<PostList> {
  final AsyncMemoizer _memoizer = AsyncMemoizer();

  bool forceFetch = false;

  fetchData() {
    return this._memoizer.runOnce(() async {
      return await getData();
    });
  }

  Future getData() async{
    //retreive data from server
    var urlMod = widget.appData.url;
    if(widget.appData.whoOwnsPostsID == -1) urlMod += "/api/v1/posts";
    else urlMod += "/api/v1/users/" + widget.appData.whoOwnsPostsID.toString() + "/posts";

    return await http.get(
      urlMod, 
      headers: {HttpHeaders.authorizationHeader: "Bearer " + widget.appData.token}
    ).then((response){
        if(response.statusCode == 200){
          forceFetch = false; //in case this was triggered by it
          return jsonDecode(response.body);
        }
        else{ 
          print(urlMod + " get posts fail");
          //TODO... trigger some visual error
        }
    });
  }

  void forceReload(){
    print("force reloading post list");
    forceFetch = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: (forceFetch) ? getData() : fetchData(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if(snapshot.connectionState == ConnectionState.done){
          List list = snapshot.data;
          return ListView.builder(
            shrinkWrap: true,
            physics: ClampingScrollPhysics(),
            itemCount: list.length,
            itemBuilder: (context, index) => Post(
              appData: widget.appData,
              postID: list[index]["id"],
              caption: list[index]["caption"],
              imageUrl: list[index]["image_url"],
              timeStamp: list[index]["created_at"],
              postOwnerID: list[index]["user_id"],
              likeCount: list[index]["likes_count"],
              commentCount: list[index]["comments_count"],
              postOwnerEmail: list[index]["user_email"],
              postOwnerImageUrl: list[index]["user_profile_image_url"],
              startLiked: list[index]["liked"],
              liked: new ValueNotifier(list[index]["liked"]),
              callback: (){
                widget.callback();
                forceReload();
              },
            ),
          );
        }
        else return CustomLoading();
      },
    );
  }
}

class Post extends StatelessWidget {
  final showOptions = false;
  final showComent = false;
  final showShare = false;
  final showBookmark = false;

  final Data appData;
  final int postID;
  final String caption;
  final String imageUrl;
  final String timeStamp;
  final int postOwnerID;
  final int likeCount;
  final int commentCount;
  final String postOwnerEmail;
  final String postOwnerImageUrl;
  final bool startLiked;
  final ValueNotifier liked;
  final Function callback;
  Post({
    this.appData, //used to determine if we should have links to the other users
    this.postID,
    this.caption, //used to show the caption
    this.imageUrl, //used to show the image
    this.timeStamp, //used to indicate when the post was posted
    this.postOwnerID, //used to go to this users other posts
    this.likeCount, //display count of likes
    this.commentCount, //display count of comments
    this.postOwnerEmail, //diplays in front of the caption
    this.postOwnerImageUrl, //used to know who owns the post
    this.startLiked,
    this.liked,
    @required this.callback,
  });

  Data modForUser(appData, id){
    appData.whoOwnsPostsID = id;
    return appData;
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size.width;

    void goToComments(){
      print("going to comments for " + postID.toString());
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Comments(
            postID: postID,
            postOwnerImageUrl: postOwnerImageUrl, 
            postOwnerEmail: postOwnerEmail, 
            postCaption: caption,
            postTimeStamp: timeStamp,
            appData: appData,
            callback: callback,
          ),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              buildClickOrNoClick(context),
              (showOptions)
              ? Padding(
                padding: EdgeInsets.fromLTRB(0, 8, 8, 8),
                child: new IconButton(
                  icon: Icon(Icons.more_vert),
                  onPressed: null,
                ),
              )
              : Container()
            ],
          ),
        ),
        GestureDetector(
          onDoubleTap: () => like(postID, true),
          child: Container(
            height: size,
            width: size,
            child: new Image.network(
              imageUrl,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              new Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  GestureDetector(
                    onTap: () => like(postID, !liked.value),
                    child: AnimatedBuilder(
                      animation: liked,
                      builder: (BuildContext context, Widget child) {
                        if(liked.value){
                          return Icon(
                            FontAwesomeIcons.solidHeart,
                            color: Colors.red,
                          );
                        }
                        else{
                          return Icon(
                            FontAwesomeIcons.heart,
                          );
                        }
                      },
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      new SizedBox(
                        width: 16.0,
                      ),
                      GestureDetector(
                        onTap: () => goToComments(),
                        child: new Icon(
                          FontAwesomeIcons.comment,
                        ),
                      ),
                    ],
                  ),
                  (showShare)
                  ? Row(
                    children: <Widget>[
                      new SizedBox(
                        width: 16.0,
                      ),
                      new Icon(
                        FontAwesomeIcons.paperPlane,
                      ),
                    ],
                  )
                  : Container(),
                ],
              ),
              (showBookmark)
              ? new Icon(
                FontAwesomeIcons.bookmark,
              )
              : Container(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: AnimatedBuilder(
            animation: liked,
            builder: (BuildContext context, Widget child) {
              //adjust for client side changes without reloading
              int actualLikes = likeCount;
              if(startLiked != liked.value){
                if(liked.value) actualLikes += 1;
                else actualLikes -= 1;
              }

              //display actual likes
              return Text(
                actualLikes.toString() + ((actualLikes == 1) ? " like" : " likes"), 
                style: TextStyle(fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: (postOwnerEmail).split('@')[0],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: " " + caption,
                  style: TextStyle(color: Colors.grey),
                ),
              ]
            ),
          ),
        ),
        GestureDetector(
          onTap: () => goToComments(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              "View all comments", 
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "posted on " + timeStamp.toString(), 
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
        ),
        Container(
          height: 16,
          child: Container(),
        ),
      ],
    );
  }

  void like(postID, doWeLike){
    if(doWeLike){
      //make url
      var urlMod = appData.url + "/api/v1/posts/" + postID.toString() + "/likes";

      //use server
      http.post(
        urlMod, 
        headers: {HttpHeaders.authorizationHeader: "Bearer " + appData.token}
      ).then((response){
        //process data
        if(response.statusCode == 200){ 
          print("liking succeed");
          liked.value = doWeLike;
          //TODO... get the count of user posts... user likes... and user comments
        }
        else{ 
          print(urlMod + " liking fail");
          //TODO... trigger some visual error
        }
      });
    }
    else{
      //make url
      var urlMod = appData.url + "/api/v1/posts/" + postID.toString() + "/likes";

      //use server
      http.delete(
        urlMod, 
        headers: {HttpHeaders.authorizationHeader: "Bearer " + appData.token}
      ).then((response){
        //process data
        if(response.statusCode == 200){ 
          print("UN liking succeed");
          liked.value = doWeLike;
          //TODO... get the count of user posts... user likes... and user comments
        }
        else{ 
          print(urlMod + " UN liking fail");
          //TODO... trigger some visual error
        }
      });
    }
  }

  Widget buildClickOrNoClick(BuildContext context) {
    if(appData.whoOwnsPostsID == postOwnerID){
      return ProfileLink(
        postOwnerImageUrl: postOwnerImageUrl, 
        postOwnerEmail: postOwnerEmail,
      );
    }
    else{
      return GestureDetector(
        onTap: (){
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Profile(
                appData: modForUser(appData, postOwnerID),
                callback: callback,
              ),
            ),
          );
        },
        child: new ProfileLink(
          postOwnerImageUrl: postOwnerImageUrl, 
          postOwnerEmail: postOwnerEmail,
        ),
      );
    }
  }
}

class ProfileLink extends StatelessWidget {
  const ProfileLink({
    Key key,
    @required this.postOwnerImageUrl,
    @required this.postOwnerEmail,
  }) : super(key: key);

  final String postOwnerImageUrl;
  final String postOwnerEmail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Row(
        children: <Widget>[
          new Container(
            height: 40.0,
            width: 40.0,
            decoration: new BoxDecoration(
              shape: BoxShape.circle,
              image: new DecorationImage(
                fit: BoxFit.fill,
                image: new NetworkImage(
                  postOwnerImageUrl,
                ),
              ),
            ),
          ),
          new SizedBox(
            width: 10.0,
          ),
          new Text(
            (postOwnerEmail).split('@')[0],
            style: TextStyle(fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }
}