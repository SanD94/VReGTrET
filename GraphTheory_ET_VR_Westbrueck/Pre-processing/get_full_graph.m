function f_graph = get_full_graph(collider_list_file, is_loc)
    arguments (Input)
        collider_list_file (1,1) string = fullfile("utils", "building_collider_list.csv")
        is_loc (1,1) { mustBeNumericOrLogical } = false
    end

    arguments (Output)
        f_graph (1,1) graph
    end

    collider_list = readtable(collider_list_file);
    node_table = collider_list(:, {'Var1', 'target_collider_name', ...
        'transformed_collidercenter_x', 'transformed_collidercenter_y'});

    % Name is the convention for graph
    node_table = renamevars(node_table, ...
        ["Var1", "target_collider_name", ...
            "transformed_collidercenter_x", ...
            "transformed_collidercenter_y"], ...
        ["ID", "Name", "x", "y"]);

    [C, ia] = unique(node_table.Name);
    node_table = node_table(ia, :);
    if (is_loc)
        node_table = add_loc_graph(node_table);
    end

    f_graph = graph(false(height(node_table)), node_table);
end

