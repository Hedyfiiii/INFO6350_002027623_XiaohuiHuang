import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'to_do_list_widget.dart' show ToDoListWidget;
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
class ToDoListModel extends FlutterFlowModel<ToDoListWidget> {
  
  

  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();
  // State field(s) for ListView widget.
    
    PagingController<DocumentSnapshot?, ToDoItemsRecord>? listViewPagingController;
    Query? listViewPagingQuery;
    List<StreamSubscription?> listViewStreamSubscriptions = [];
    

  
  

  @override
  void initState(BuildContext context) {
    

    
  }

  @override
  void dispose() {
    unfocusNode.dispose();
    for (var s in listViewStreamSubscriptions) {
      s?.cancel();
    }
    listViewPagingController?.dispose();
    
    
    
  }

  

  
  /// Additional helper methods.
    PagingController<DocumentSnapshot?, ToDoItemsRecord> setListViewController (
    
    Query query, {
    DocumentReference<Object?>? parent,
  }) {
    listViewPagingController ??= _createListViewController(  query, parent);
    if (listViewPagingQuery != query) {
      listViewPagingQuery = query;
      listViewPagingController?.refresh();
    }
    return listViewPagingController!;
  }

  PagingController<DocumentSnapshot?, ToDoItemsRecord> _createListViewController (
    
    Query query,
    DocumentReference<Object?>? parent,
  ) {
    final controller =
        PagingController<DocumentSnapshot?, ToDoItemsRecord>(firstPageKey: null);
    return controller
      ..addPageRequestListener(
        (nextPageMarker) => queryToDoItemsRecordPage(queryBuilder: (_) => listViewPagingQuery ??= query,nextPageMarker: nextPageMarker,streamSubscriptions: listViewStreamSubscriptions,controller: controller,pageSize: 25,isStream: true,),
      );
  }
  
}
