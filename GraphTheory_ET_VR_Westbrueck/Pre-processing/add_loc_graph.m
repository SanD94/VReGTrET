function loc_table = add_loc_graph(node_table, restrict_coord_file)
    arguments (Input)
        node_table table
        restrict_coord_file (1,1) string = fullfile("..", "additional_Files", "restricted_area_coord_hera.txt")
    end

    pos = readmatrix(restrict_coord_file);
    xq = node_table.x;
    yq = node_table.y;
    loc_table = node_table;
    loc_table.inside = inpolygon(xq, yq, pos(:,1), pos(:,2));
end