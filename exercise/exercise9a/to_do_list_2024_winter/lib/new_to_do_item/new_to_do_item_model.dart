import '/flutter_flow/flutter_flow_util.dart';
import 'new_to_do_item_widget.dart' show NewToDoItemWidget;
import 'package:flutter/material.dart';
class NewToDoItemModel extends FlutterFlowModel<NewToDoItemWidget> {
  
  

  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();
final formKey = GlobalKey<FormState>();
  // State field(s) for task widget.
FocusNode? taskFocusNode;
TextEditingController? taskTextController;
String? Function(BuildContext, String?)? taskTextControllerValidator;
  // State field(s) for description widget.
FocusNode? descriptionFocusNode;
TextEditingController? descriptionTextController;
String? Function(BuildContext, String?)? descriptionTextControllerValidator;
DateTime? datePicked;
bool isDataUploading = false;
  FFUploadedFile uploadedLocalFile = FFUploadedFile(bytes: Uint8List.fromList([]));
  String uploadedFileUrl = '';
  

  
  

  @override
  void initState(BuildContext context) {
    

    
  }

  @override
  void dispose() {
    unfocusNode.dispose();
taskFocusNode?.dispose();
        taskTextController?.dispose();
        
descriptionFocusNode?.dispose();
        descriptionTextController?.dispose();
        
    
    
  }

  

  
  
  
}
