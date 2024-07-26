mixin tt {
  void doSomething() {
    print("tt");
  }
}
class T with tt{}
class S extends T {}
 main(){
   var t = S();
   ttAction(t);
 }

 void ttAction(tt a){
   print("ttAction");
 }