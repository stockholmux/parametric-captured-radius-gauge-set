include <BOSL2/std.scad>

// render the outer case
render_case= true;
// render the gauges ("leafs")
render_leafs= true;
// render the decoupling layer
render_decoupling= true;

// gauge sizes from minimal to max, must be whole numbers
sizes= [1:10];
// render an individual leaf (must be less than the upper limit of `size`) 
render_individual_leaf= -1;
// length of the case
length= 70;
// width of the "supports" at all 4 corners of the case
side_w= 5;
// thickness of an individual leaf
leaf_thickness= 1;
// clearance used between each gauge
leaf_spacing= 0.15;
// case dimension: x is the x of the support, y is the y of the support, z is the thickness of the case; note: you may need to tweak both x and z because of the chamfering 
case_thickness= [2, 10, 1.2];
// the centre section, expressed percent (0-1) of the `length`
mid_size= 0.5;
// the x and y tolerance of the decoupling layer
decoupling_tolerance= [0.05, 0.025];
// the x and y tolerance of the case
case_tolerance= [0.025, 0];
// how far the tab sticks out
tab_extension= 3;
// the x and y dimensions (square) of the tab with the number
tab_size= 14;
// the text size expressed as a percent (0-1) of the tab size
text_to_tab_size= 0.5;
// depth of the engraving of the text
text_depth= 0.4;

epsilon= 0.01;

max_x= sizes[2];
leaf_count = sizes[2] - sizes[0];
total_leaf_height= leaf_thickness + leaf_spacing;
d= max_x*2;
center_bar_l= length - ((max_x + side_w) * 2);
center_bar_w=  d - (side_w*2);
leaf_dims= [d, length, leaf_thickness];
inner_cube_dims= [leaf_dims.x, leaf_dims.y-d];
h= (leaf_count+2) * total_leaf_height;
tab_w = (center_bar_l * mid_size) - case_thickness.y;
//max_travel= (center_bar_l - (case_thickness.y * 2))/2;
tab_center_position= [max_x + tab_extension + (tab_size/2), -tab_w, leaf_thickness - text_depth + epsilon];
case_xy_dims= inner_cube_dims_with_adj([1 + case_tolerance.x, 1 + case_tolerance.y]);
case_chamfer= case_thickness.x/2;

if (render_case) color("lightblue") {
    case_top_bottom();
    case_mid();
    translate([0, 0, upper_z(leaf_count+2) + case_thickness.z])
        rotate([0, 180, 0])
            case_top_bottom();
    mirror_copy([0, 1, 0])
        mirror_copy([1, 0, 0]) 
            side_post();
}

if (render_decoupling) color("yellow")
    decoupler();

if (render_leafs) 
    if (render_individual_leaf == -1) {
        translate([0, 0, case_thickness.z])
            for(i = [sizes[0] : sizes[2]]) 
                translate([0, 0, (i - sizes[0])  * total_leaf_height]) 
                    leaf_3d(i);
    } else {
        leaf_3d(render_individual_leaf);
    }

module leaf_3d(i)
        difference() {
            linear_extrude(leaf_thickness)
                    leaf(i);
            translate([i % 2 ? -tab_center_position.x : tab_center_position.x, 
            -tab_center_position.y,
            tab_center_position.z])
                linear_extrude(text_depth)
                    text(str(i), halign= "center", valign= "center", size= tab_size * text_to_tab_size);
        }
      
function upper_z(n) = n * total_leaf_height + case_thickness.z;

module decoupler()
    translate([0, 0, upper_z(leaf_count+1)])
        linear_extrude(leaf_thickness)
            difference() {
                inner_cube();
                inner_mid([1 + decoupling_tolerance.x, mid_size + decoupling_tolerance.y]);
            }

module side_post() 
    translate([(inner_cube_dims.x * (1+case_tolerance.x))/2, (inner_cube_dims.y/2 * (1+case_tolerance.y)) - case_thickness.y/2]) 
        half_round_cube([case_thickness.x, case_thickness.y, h + (case_thickness.z * 2)], dir= RIGHT, chamfer= case_chamfer);
    

module case_mid()
    linear_extrude(h + (case_thickness.z * 2))
        inner_mid([1, mid_size]);

module case_top_bottom() {
    case_xy_dims= inner_cube_dims_with_adj([1 + case_tolerance.x, 1 + case_tolerance.y]);
    difference() {
        cuboid([case_xy_dims.x, case_xy_dims.y, case_thickness.z], anchor= BOTTOM, chamfer= case_chamfer, edges= [FRONT + BOTTOM, BACK + BOTTOM]);
        mirror_copy([1, 0, 0])
            translate([(case_xy_dims.x + case_thickness.x)/2,0,-case_chamfer])
                half_round_cube(
                    [case_thickness.x, case_xy_dims.y - (case_thickness.y*2) + + case_chamfer*2, case_chamfer*2],
                    LEFT ,
                    case_chamfer
                );
    }
}
    
module half_round_cube(dims, dir, chamfer)
    translate([dims.x/2 * dir.x, 0, 0]) {
        translate([dims.x/4 * -dir.x, 0, 0]) 
            cuboid([dims.x/2, dims.y, dims.z], chamfer= chamfer, edges= [FRONT + BOTTOM, FRONT + TOP, BACK + BOTTOM, BACK + TOP ], anchor= BOTTOM);
        hull() 
            mirror_copy([0, 1, 0])
                translate([0, (dims.y - dims.x)/2, 0]) 
                    cyl(d= dims.x, l= dims.z, chamfer= chamfer, $fn= 30, anchor= BOTTOM);
    }

    

module leaf(r) {
    difference() {
        union() {
            hull() {
                inner_cube();
                leaf_convex_end_stop(r, leaf_dims.y);
                mirror([0, 1, 0])
                    leaf_convex_end_stop(r, leaf_dims.y);
            }
            leaf_end(r, leaf_dims.y);

            mirror([r % 2, 0, 0])
                translate([max_x, -tab_w/2]) {
                    square([tab_extension, tab_w]);
                    translate([tab_extension, 0]) 
                        hull() {
                            square([epsilon, tab_w]);
                            translate([0, 
                                tab_w
                            ])
                                square([tab_size, tab_w]);
                        }
                }
        }
        inner_mid();
        translate([0, -leaf_dims.y/2])
            circle(r= r, $fn= $preview ? 30 : 70);
    }
}

module inner_mid(adj=[1,1])
    square([center_bar_w * adj.x, center_bar_l * adj.y], center= true);

function inner_cube_dims_with_adj(adj) = [inner_cube_dims.x * adj.x, inner_cube_dims.y * adj.y];

module inner_cube(adj=[1,1])
    square(inner_cube_dims_with_adj(adj), center= true);

module leaf_convex_end_stop(r, y)
    translate([0, (y - r)/2, 0])
        square([r*2, epsilon], center= true);

module leaf_end(r, y)
    translate([0, (y - r)/2, 0])
        circle(r= r, $fn= $preview ? 30 : 70);
