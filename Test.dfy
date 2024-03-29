include "AVLnode.dfy"
include "AVLtree.dfy"

method Main() {
    var avlTree: AVLtree := new AVLtree();
    var avlNode: AVLnode := new AVLnode(5);
    assert(avlTree.balanced());
    assert(avlNode.balanced());
    var height: int := avlTree.nodeHeight(avlTree.root);
    var heightDiff: int := avlTree.heightDiff(avlTree.root);
    print height, "\n";
    print heightDiff;
}