import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
      import 'to_do_list_model.dart';
      export 'to_do_list_model.dart';
    
class ToDoListWidget extends StatefulWidget {
  const ToDoListWidget({super.key }) ;

  

  @override
  State<ToDoListWidget> createState() => _ToDoListWidgetState();
}

class _ToDoListWidgetState extends State<ToDoListWidget>  {
  late ToDoListModel _model;

final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ToDoListModel());

    
    
  }


  @override
  void dispose() {
    _model.dispose();

    
    super.dispose();
  }

  
  @override
  Widget build(BuildContext context) {
    
    return GestureDetector(
  onTap: () =>
    _model.unfocusNode.canRequestFocus
      ? FocusScope.of(context).requestFocus(_model.unfocusNode)
      : FocusScope.of(context).unfocus(),
  child: Scaffold(
      key: scaffoldKey,
      
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground  ,
      floatingActionButton: FloatingActionButton(
      
      onPressed:  () async {    
    context.pushNamed(
      'NewToDoItem'
      
      
      
      
      
    );
  },
      backgroundColor: FlutterFlowTheme.of(context).primary  ,
      
      elevation: 8.0,
      child:  Icon(
      
      Icons.add,
      color: FlutterFlowTheme.of(context).info  ,
      size: 24.0  ,
    )  ,
    ),
      
      
      appBar:           AppBar(
            
                  backgroundColor: FlutterFlowTheme.of(context).primaryBackground  ,
      
      automaticallyImplyLeading: false,
      
      title: Text(
      
       'ToDo List'  ,
      
      
      style: FlutterFlowTheme.of(context).displaySmall.override(    fontFamily: 'Outfit',
    
    
    letterSpacing: 0.0,
    
    
    
    
    
  ),
      
      
    ),
      actions: [Padding(
             padding: EdgeInsets.all( 5.0),
             child: FFButtonWidget(
      
      onPressed:  () async {GoRouter.of(context).prepareAuthEvent();
await authManager.signOut();
GoRouter.of(context).clearRedirectLocation();

    
    context.goNamedAuth(
      'Login',
      context.mounted
      
      
      
      
    );
  },
      text: 'Logout'  ,
      
      options: FFButtonOptions(
        
        height: 40.0  ,
        padding: EdgeInsetsDirectional.fromSTEB(
       24.0,
       0.0,
       24.0,
       0.0
  ),
        iconPadding: EdgeInsetsDirectional.fromSTEB(
       0.0,
       0.0,
       0.0,
       0.0
  ),
        color: FlutterFlowTheme.of(context).primary  ,
        textStyle: FlutterFlowTheme.of(context).titleSmall.override(    fontFamily: 'Readex Pro',
    color:  Colors.white  ,
    
    letterSpacing: 0.0,
    
    
    
    
    
  ),
        elevation: 3.0  ,
        borderSide: BorderSide(
      color: Colors.transparent  ,
      width: 1.0  ,
    ),
        borderRadius: BorderRadius.circular( 8.0  ),
        
        
        
        
        
        
      ),
      
    ),
           )
           ,],
      
      
      centerTitle: false,
      
      elevation: 0.0,

          ),
body: SingleChildScrollView(
        
        
        
        child: Column(
      
      mainAxisSize: MainAxisSize.max,
      
      
      children: [Padding(
             padding: EdgeInsetsDirectional.fromSTEB(
       0.0,
       12.0,
       0.0,
       0.0
  ),
             child:       PagedListView<DocumentSnapshot<Object?>?, ToDoItemsRecord>(
        
        pagingController: _model.setListViewController(ToDoItemsRecord.collection.orderBy('DueDate'),),
        padding: EdgeInsets.zero,
        primary: false,
        shrinkWrap: true,
        reverse: false,
        scrollDirection: Axis.vertical,
        
        builderDelegate: PagedChildBuilderDelegate<ToDoItemsRecord>(
          // Customize what your widget looks like when it's loading the first page.
          firstPageProgressIndicatorBuilder: (_) => Center(child: SizedBox(
          width: 50.0,
          height: 50.0,
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(FlutterFlowTheme.of(context).primary,),),
        ),),
          // Customize what your widget looks like when it's loading another page.
          newPageProgressIndicatorBuilder: (_) => Center(child: SizedBox(
          width: 50.0,
          height: 50.0,
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(FlutterFlowTheme.of(context).primary,),),
        ),),
          
          itemBuilder: (context, _, listViewIndex) {
    final listViewToDoItemsRecord = _model.listViewPagingController!.itemList![listViewIndex];
            return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap:  () async {    
        print('DEBUG: Navigating with address: ${listViewToDoItemsRecord.address}');
        print('DEBUG: Navigating with lat: ${listViewToDoItemsRecord.latitude}');
        print('DEBUG: Navigating with lng: ${listViewToDoItemsRecord.longitude}');
    context.pushNamed(
  'ToDoItemDetails',
  queryParameters: {
    'title': serializeParam(listViewToDoItemsRecord.title, ParamType.String),
    'description': serializeParam(listViewToDoItemsRecord.description, ParamType.String),
    'image': serializeParam(listViewToDoItemsRecord.imageURL, ParamType.String),
    'address': serializeParam(listViewToDoItemsRecord.address, ParamType.String),
    'latitude': serializeParam(listViewToDoItemsRecord.latitude, ParamType.double),
    'longitude': serializeParam(listViewToDoItemsRecord.longitude, ParamType.double),
  }.withoutNulls,
);
  },
      
      
      child: ListTile(
      
      
      title: Text(
      
       listViewToDoItemsRecord.title  ,
      
      
      style: FlutterFlowTheme.of(context).titleLarge.override(    fontFamily: 'Outfit',
    
    
    letterSpacing: 0.0,
    
    
    
    
    
  ),
      
      
    ),
      subtitle: Text(
      
       listViewToDoItemsRecord.description  ,
      
      
      style: FlutterFlowTheme.of(context).labelMedium.override(    fontFamily: 'Readex Pro',
    
    
    letterSpacing: 0.0,
    
    
    
    
    
  ),
      
      
    ),
      trailing:  Icon(
      
      Icons.arrow_forward_ios,
      color: FlutterFlowTheme.of(context).secondaryText  ,
      size: 20.0  ,
    )  ,
      tileColor: FlutterFlowTheme.of(context).secondaryBackground  ,
      dense: false,
      
      
    ),
    )
    ;
  },
        ),
      ),
           )
           ,],
    ),
      ),
    ),
)
;
  }

  
}
