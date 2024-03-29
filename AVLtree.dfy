include "AVLnode.dfy"
include "HelperFunctions.dfy"

class AVLtree {
    ghost var objects: set<object> // tree and nodes

    var root: AVLnode?

    constructor () 
        ensures objects == {this}
        ensures root == null
        ensures valid() 
        ensures fresh(objects - {this})
        ensures balanced()
    {
        objects := {this};
        root := null;
    }

    // need for balance()
    predicate valid()
        reads this, objects
    {
        root != null ==> (root in objects && root.nodes < objects)
    }

    predicate balanced()
        reads this, objects
    {
        valid() &&
        root != null ==> root.balanced()
    }

    static method nodeHeight(avlNode: AVLnode?) returns (height: int) 
    {
        if avlNode == null {
            height := -1;
        } else {
            height := avlNode.height;
        }
    }

    method heightDiff(avlNode: AVLnode?) returns (diff: int) 
    {
        if avlNode == null {
            diff := 0;
        } else {
            var leftHeight: int := nodeHeight(avlNode.left);
            var rightHeight: int := nodeHeight(avlNode.right);
            diff := leftHeight - rightHeight;
        }
    }

    method findNode(node: AVLnode, queryNum: int) returns (found_node: AVLnode?)
        requires node.valid()
        ensures found_node != null ==> found_node in node.nodes
        // Why is this not working?
        // ensures found_node != null ==> found_node.key == queryNum
        decreases node.nodes 
    {
        var temp: AVLnode? := node;
        if temp != null
        {
            if (temp.left != null && queryNum < node.key) {
                temp := findNode(temp.left, queryNum);
            }
            else if (temp.right != null && queryNum > node.key) {
                temp := findNode(temp.right, queryNum);
            }
        }

        return temp;
    }

    /* skip verification for now to implement insert and delete first */
    method {:verify false} minNode(node: AVLnode) returns (min_node: AVLnode?)
        requires node.valid()
        ensures min_node != null ==> min_node in node.nodes
        ensures min_node != null ==> (forall i :: i in node.keys ==> min_node.key <= i)
    {
        var temp: AVLnode := node;

        while temp.left != null 
            decreases if temp.left != null then temp.left.nodes else {}
        {
            temp := temp.left;
        }

        return temp;
    }
    
    method rightRotate(z: AVLnode) returns( y : AVLnode)
        requires z.left != null;
        requires z.valid();
        modifies z.nodes;
        ensures old(z.nodes) == y.nodes;
        ensures old(z.keys) == y.keys;
        ensures y.valid();
        ensures z.valid();
        ensures y == old(z.left);
        ensures y.left == old(y.left);
        ensures y.right == old(z);
        ensures z.left == old(z.left.right);
        ensures z.right == old(z.right);
    {
        y := z.left;
        var T3 := y.right;
        y.right := z;
        z.nodes := z.nodes - z.left.nodes;
        z.keys := z.keys - z.left.keys;
        z.left := T3;

        if z.left != null {
            z.nodes := z.nodes + z.left.nodes + {z.left};
            z.keys := z.keys + z.left.keys + {z.key};
        }
        if y.right != null {
            y.nodes := y.nodes + y.right.nodes + {y.right};
            y.keys := y.keys + y.right.keys + {y.key};
        }
        var r_h:int := nodeHeight(z.right);
        var l_h:int := nodeHeight(z.left);
        z.height := 1 + max(r_h,l_h);
        r_h := nodeHeight(y.right);
        l_h := nodeHeight(y.left);
        y.height := 1 + max(r_h,l_h);
    }

    method leftRotate(z: AVLnode) returns( y : AVLnode)
        requires z.right != null;
        requires z.valid()
        modifies z.nodes;
        ensures old(z.nodes) == y.nodes;
        ensures old(z.keys) == y.keys;
        ensures y.valid();
        ensures z.valid();
        ensures y == old(z.right);
        ensures y.right == old(y.right);
        ensures y.left == old(z);
        ensures z.right == old(z.right.left);
        ensures z.left == old(z.left);
    {
        y := z.right;
        var T3 := y.left;
        y.left := z;
        z.nodes := z.nodes - z.right.nodes;
        z.keys := z.keys - z.right.keys;
        z.right := T3;
        if z.right != null {
            z.nodes := z.nodes + z.right.nodes + {z.right};
            z.keys := z.keys + z.right.keys + {z.key};
        }
        if y.left != null {
            y.nodes := y.nodes + y.left.nodes + {y.left};
            y.keys := y.keys + y.left.keys + {y.key};
        }
        var r_h:int := nodeHeight(z.right);
        var l_h:int := nodeHeight(z.left);
        z.height := 1 + max(r_h,l_h);
        r_h := nodeHeight(y.right);
        l_h := nodeHeight(y.left);
        y.height := 1 + max(r_h,l_h);
    }

    method leftRightRotate(z: AVLnode) returns( y : AVLnode)
        modifies z.nodes
        requires z.valid()
        ensures y.valid()
        ensures y.balanced()
        ensures z.valid()
        ensures old(z.nodes) == y.nodes;
        ensures old(z.keys) == y.keys;
        ensures y.right != null ==> y.right in y.right.nodes;
        ensures y.left != null ==> y.left in y.left.nodes;
    {
        y := z;
        if z.left != null && y.left != null && y.left.right != null{
            y.left := leftRotate(y.left);
            y:= rightRotate(y);
        }
        
    }

    method rightLeftRotate(z: AVLnode) returns( y : AVLnode)
        modifies z.nodes
        requires z.valid()
        ensures y.valid()
        ensures y.balanced()
        ensures z.valid()
        ensures old(z.nodes) == y.nodes;
        ensures old(z.keys) == y.keys;
        ensures y.right != null ==> y.right in y.right.nodes;
        ensures y.left != null ==> y.left in y.left.nodes;
    {
        y := z;
        if z.right != null && y.right != null && y.right.left != null{
            y.right := rightRotate(y.right);
            y:= leftRotate(y);
        }
        
    }

    method insert(key: int) 
        requires valid()
        modifies objects;
        modifies root;
        ensures valid() && balanced();
        //ensures fresh(objects - old(objects));
        //ensures root != null && old(root) != null ==> root.keys == old(root.keys) + {key};
    {
        root := insert2(root, key);
        assert root.valid();
        objects := root.nodes + {this};
    }

    method insert2(node:AVLnode?, key: int) returns(ret : AVLnode)
        requires node == null || (node.valid() && node.balanced())
        modifies if node != null then node.nodes + {node} else {}
        decreases if node == null then {} else node.nodes
        ensures node == null ==> fresh(ret.nodes) && ret.keys == {key}
        ensures ret.valid() && ret.balanced()
        ensures node == null ==> fresh(ret.nodes) && ret.keys == {key}
        //ensures node != null ==> ret.keys == old(node.keys) + {key}
        //ensures node != null ==> fresh(ret.nodes - old(node.nodes))
    {
        if (node == null){
            ret:= new AVLnode(key);
            return ret;
        } else {
            if (key < node.key) {
                assert node.right == null || node.right.valid();
                var t := insert2(node.left,key);
                node.left := t;
                node.nodes := node.nodes + node.left.nodes;
                node.keys := node.keys + {key};
            } else if (key > node.key){
                assert node.left == null || node.left.valid();
                node.right := insert2(node.right,key);
                node.nodes := node.nodes + node.right.nodes;
                node.keys := node.keys + {key};
            }

            var l_h := nodeHeight(node.left);
            var r_h := nodeHeight(node.right);
            node.height := max(l_h, r_h + 1);
            var balance := heightDiff(node);

            /*Left Left */
            if (balance > 1 && key < (node.left.key))
            {
                ret:= rightRotate(node);
                return ret;
            }   

            /*Right Right */
            if (balance < -1 && key > (node.right.key))
            {
                ret:= leftRotate(node);
                return ret;
            }    

            /*Left Right */
            if (balance > 1 && key > (node.left.key))
            {
                ret := leftRightRotate(node);
            }

            /*Right Left */
            if (balance < -1 && key < (node.right.key))
            {
                ret := rightLeftRotate(node);
            }
        }      
    }

    // Task 1
    /*
    // for debug
    method printAVLtree()
        requires balanced()
    {
        
    }
     */

    
    // Task 2
    /*
    method insert(node: AVLnode, key: int) returns (result: AVLnode)
        // if node is null, call new node func and set key height to 0
        ensures balanced()
        //requires valid()
        
    {
        if (node == null){
            // need an insert helper function??
            return;
        }

        // logic 
        if (key < node.key){ 
            //call func that sets node->root to key, left = null, right = null
            node.left:= insert(node.left,key);
            
        }
        else if (key > node.key)
        {
            node.right := insert(node.right,key);
        }
        // node height
        var tmp: int:= nodeHeight(node.left);
        var tmp2: int:= nodeHeight(node.right);
        node.height := (max(tmp,tmp2) +1);
        
        var balance : int:= heightDiff(node);

        //implement LL rotate
        if (balance > 1 && key < (node.left.key)){
            
            var tmpnode: AVLnode:= rightRotate(node);
            return tmpnode;
        } 
        //RR rotate
        if(balance < -1 && key > (node.right.key)){
            var tmpnode2: AVLnode:= leftRotate(node);
            return tmpnode2;
        }


        //LR rotate
        if (balance >1 && key > (node.left.key)){
            node := leftRightRotate(node);
        }

        //RL rotate
        if(balance < -1 && key < (node.right.key)){
            node := rightLeftRotate(node);
        }
    
    return result;

    }



    method delete(key: int) 
        
    {
    
    }
    
    */
}