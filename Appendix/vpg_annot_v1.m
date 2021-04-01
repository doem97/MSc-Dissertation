% Matlab code to convert caltech annot. into VPGNet annot.
% Usage: Download Caltech Lanes dataset and change path & dir parameter 
% <Directory structure>
% |__ caltech-lanes-dataset (download dataset[1])
%     |__ caltech-lane-detection/matlab (copy 'caltech-lane-detection/matlab' [2])
%     |__ cordova1
%     |__ cordova2
%     |__ washington1
%     |__ washington2
%     |__ vpg_annot_v1.m (current code)
%     |__ output.txt (output list file)

clear all; 
close all; clc;

%% startup (change category)
category = 'cordova2';
% category = 'cordova2';
% category = 'washington1';
% category = 'washington2';
addpath(genpath('./caltech-lane-detection/matlab'))

path = 'D:\workspace\vpgnet\VPGNet\caltech-lanes-dataset';
% change path
file =  sprintf('/%s/labels.ccvl', category);
gLabelData = ccvLabel('read', [path file]);

%% spline & grid mask parameters 
h = 0.02;           % interval for splines
height = 480;       % reference image height
width = 640;        % reference image width
gg = 8;             % grid size for binary mask
grid_x = 1:gg:481;
grid_y = 1:gg:641;
thickness = 2;

%% make annotation file
fileID = fopen(sprintf('./%s.txt', category),'w');
numFrames = size(gLabelData.frames,2);
gLabelSubtypes = {'bw', 'sw', 'dy', 'by', 'sy'};
    
for i = 1:numFrames
    % i is the index of frame
    disp(sprintf('frame: %03d',i))
    numLanes = size(gLabelData.frames(i).labels, 2);
    %numLanes is howmany symbol lines detected in pic
    segs = [];
    splines = {numLanes};
    sptypes = {numLanes};
    for j = 1:numLanes
        splines{j} = ccvEvalBezSpline(gLabelData.frames(i).labels(j).points, h);
        % convert 4 point to spline (just join them as a straight line)
        sptypes{j} = gLabelData.frames(i).labels(j).subtype;
        splines_x1 = splines{j};
        splines_x2 = splines{j};
        splines_x1(:,1) = splines_x1(:,1) - thickness;
        splines_x2(:,1) = splines_x2(:,1) + thickness;
        splines{j} = [splines{j}; splines_x1; splines_x2];
        
        for k = 1:size(splines{j},1)
        % make spline points into bounding box
            grid_pos_x = floor((splines{j}(k,1)-1)/gg);
            grid_pos_y = floor((splines{j}(k,2)-1)/gg);
            xmin = grid_pos_x * gg + 1;
            xmax = grid_pos_x * gg + gg;
            ymin = grid_pos_y * gg + 1;
            ymax = grid_pos_y * gg + gg;
            grid_width = xmax - xmin; % ? always 7, gg - 1
            grid_height = ymax - ymin;
            inst_id = j;
            lane_id = find(ismember(gLabelSubtypes, sptypes{j}));
            segs = [segs; xmin, ymin, xmax, ymax, inst_id, lane_id];
        end
        segs = unique(segs, 'rows');
    end    
    numLaneSegs = size(segs, 1) - numLanes;
    fprintf(fileID,'/%s/f%05d.png  %d',category, i-1, size(segs,1));

    % img_path = sprintf('%s\\f%05d.png',category,i-1);
    % img = imread(img_path);
    % figure(99);
    % imshow(img);
    % hold on;

    for j = 1:size(segs,1)    
        xmin = segs(j,1);
        ymin = segs(j,2);
        xmax = segs(j,3);
        ymax = segs(j,4);
        inst_id = segs(j,5);
        lane_id = segs(j,6);
        
        fprintf(fileID, ' ');
        
        fprintf( fileID, ' %d', xmin );
        fprintf( fileID, ' %d', ymin );
        fprintf( fileID, ' %d', xmax );
        fprintf( fileID, ' %d', ymax );
        % rectangle('Position', [xmin ymin xmax-xmin ymax-ymin])
        % NO inst_id CAUSE DONT CARE
        fprintf( fileID, ' %d', lane_id ); % depth data -> lane_id        
    end
    
    % waitforbuttonpress;
    
    fprintf(fileID,'\n');
        
end

fclose('all');
