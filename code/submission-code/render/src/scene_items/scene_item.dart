import '../key.dart';
import '../process_items.dart';

abstract class SceneItem {
  SceneItem({this.label = ''});

  final String label;
  // KeyD key;

  /* TODO:
      - Change name convention to put "DR" or something afterwards, like "Widget"
        - Perhaps change to "dScale" or
      - How are keys handled and passed down in Groups?
        - Make '.key' a super thing? like with widgets?
        - Keys are only used for ProcessItem Layers and Tris. Should keys stack
          if multiple keys are provided but collapsed?
        - Keys can be pre-provided in the pre-built Items
        - Do I even need keys?? First figure out how sorting will work
      - Change "Color" to a more generic surface / texture type?
      - Make all inputted vectors .clone to prevent reference bugs
      - Remove most of the '.from' constructors as they make it harder to read.
        The default way of creating a shape should be the least verbose.
      - Have a 'convex hull' ProcessItem group, which simply sorts by midpoint.
        - How to modify the ProcessItem types to support extension?
        - We want to keep ProcessItem to be the minimal interface. We should expose
          common interfaces that may support future
  */
  List<ProcessItem> compile();
}