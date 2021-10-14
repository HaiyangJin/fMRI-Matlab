function area = sf_triarea(mat)
% area = sf_triarea(mat)
%
% This function calculates the area of a triangle given the vertex 
% coordiantes or two vectors. 
%
% Input:
%     mat      <matrix> if 'mat' is Nx3, each column stores the coordiantes 
%               for each vertex; if 'mat' is Nx2, each column is one vector.
%
% Output:
%     area     <numeric> the area of the triangle.
% 
% Created by Haiyang Jin (1-July-2020)

[nRow, nCol] = size(mat);

if ~ismember(nCol, [2, 3])
    if ismember(nRow, [2, 3])
        mat = mat';
        nCol = size(mat, 2);
    else
        error('The column of ''mat'' has to be 3 [coordinates] or 2 [vector].');
    end
end

% convert coordinates to vectors
if nCol == 3
    vecMat = mat(:, 2:3)-mat(:, 1);
else
    vecMat = mat;
end

% calculate the area
area = 1/2 * norm(cross(vecMat(:, 1), vecMat(:, 2)));

end