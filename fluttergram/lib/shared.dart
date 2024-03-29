import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttergram/home.dart';
import 'package:fluttergram/newOrEdit.dart';
import 'package:fluttergram/profile.dart';
import 'package:image_picker/image_picker.dart';

import 'package:outline_material_icons/outline_material_icons.dart';

class BottomBarSpacer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
    );
  }
}

class BottomNav extends StatelessWidget {
  final Data appData;
  final int selectedMenuItem;

  BottomNav({
    @required this.appData,
    @required this.selectedMenuItem,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'bottomNav',
      //NOTE: this material widget is required so during our transition to another page we dont get an error
      //even if every page technically has a material ancestor because of the scaffold
      //also also technically doesnt while its transition to the other page
      child: Material(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Colors.grey,
                width: 1,
              ),
            ),
          ),
          child: new Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            //NOTE: you CANT have this set to stretch
            // crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              MenuItem(
                appData: appData,
                thisMenuItem: 0,
                selectedMenuItem: selectedMenuItem,
                menuIcon: (selectedMenuItem == 0) ? Icons.home : OMIcons.home,
              ),
              MenuItem(
                appData: appData,
                thisMenuItem: 1,
                selectedMenuItem: selectedMenuItem,
                menuIcon: (selectedMenuItem == 1) ? Icons.add_box : OMIcons.addBox,
              ),
              MenuItem(
                appData: appData,
                thisMenuItem: 2,
                selectedMenuItem: selectedMenuItem,
                menuIcon: (selectedMenuItem == 2) ? Icons.account_box : OMIcons.accountBox,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MenuItem extends StatelessWidget {
  final Data appData;
  final int thisMenuItem;
  final int selectedMenuItem;
  final IconData menuIcon;

  const MenuItem({
    this.appData,
    this.thisMenuItem,
    this.selectedMenuItem,
    this.menuIcon,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: (){
        print("this menu item " + thisMenuItem.toString());
        if(thisMenuItem == 1){
          print("selecting image");
          //ADD reload (for now)
          selectImage(false, context, appData); //from gallery
        }
        else{
          if(thisMenuItem != selectedMenuItem){
            print("pushing new route");
            Navigator.push(
              context,
              MaterialPageRoute(
                //NOTE: this MUST be like this
                builder: (context) => navFunc(appData, thisMenuItem),
              ),
            );
          }
          else{
            print("reloading route");
            //HOME and PROFILE reloads

            //NOTE: profile will always reload 
            //since its never at the begining of the stack

            popPushOrReplace(context, appData, thisMenuItem);
          }
        }
      },
      icon: Icon(menuIcon),
    );
  }
}

Widget navFunc(Data appData, int thisMenuItem){
  switch(thisMenuItem){
    case 0:
      //selectedMenuItem always 0
      return Home(appData: appData); 
    break;
    case 1:
      //selectedMenuItem always 1
      return NewOrEditPost(appData: appData, isNew: true);
    break;
    default:
      //selectedMenuItem FROM HERE is always 2
      return Profile(
        email: "", //it will be read in soon
        appData: modForUser(appData, appData.currentUserID),
        selectedMenuItem: 2,
      );
    break;
  }
}

class Data {
  String url = "https://serene-beach-48273.herokuapp.com";
  String token = "";
  int currentUserID;
  int whoOwnsPostsID;
}

Data modForUser(Data appData, int id){
  Data newAppData = new Data();
  newAppData.token = appData.token;
  newAppData.url = appData.url;
  newAppData.currentUserID = appData.currentUserID;
  newAppData.whoOwnsPostsID = id;
  return newAppData;
}

Data modForAllPosts(Data appData){
  //-1 is the secret code for allposts
  return modForUser(appData, -1); 
}

void goToUserProfile(BuildContext context, Data appData, int profileUserID, String profileUserEmail, int selectedMenuItem, {bool reload}){
  Data newAppData = modForUser(appData, profileUserID);
  if(reload){
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Profile(
          email: profileUserEmail,
          appData: newAppData,
          selectedMenuItem: selectedMenuItem,
        ),
      ),
    );
  }
  else{
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Profile(
          email: profileUserEmail,
          appData: newAppData,
          selectedMenuItem: selectedMenuItem,
        ),
      ),
    );
  }
}

void popPushOrReplace(BuildContext context, Data appData, int thisMenuItem) async{
  
}

class TopBar extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget trailing;

  TopBar({
    this.leading,
    @required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(45),
      child: Hero(
        tag: 'topBar',
        child: AppBar(
          backgroundColor: new Color(0xfff8faf8),
          elevation: 1.0,
          centerTitle: false,
          leading: (leading != null) ? leading : BackButton(),
          title: title,
          actions: <Widget>[
            (trailing != null) ? trailing : Container(),
          ],
        ),
      ),
    );
  }
}

Future selectImage(bool fromCamera, BuildContext context, Data appData) async {
  //grab the image in your desired method
  File image = await ImagePicker.pickImage(
    source: (fromCamera) ? ImageSource.camera : ImageSource.gallery,
  );

  if(image != null){
    //navigate to the page where we plugin our caption
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewOrEditPost(
          appData: appData, 
          isNew: true,
          newImage: image,
        ),
      ),
    );
  }
}