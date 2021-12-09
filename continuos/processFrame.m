function [S, T_W_C_curr] = processFrame(S0, img0, img1, K,params)
% The continuous VO pipeline is the core component of the proposed VO implementation. 
% Its responsibilities are three-fold:
% 1. Associate keypoints in the current frame to previously triangulated landmarks.
% 2. Based on this, estimate the current camera pose.
% 3. Regularly triangulate new landmarks using keypoints not associated to previously triangulated
% landmarks.
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to process each frame, handler of the continuos VO pipeline
% input --> the 2 images RGB or GRAYSCALE, and the previous state
% output --> S : the state (a struct) containing a [2,k] matrix rapresenting 2d keypoint coordinates and a 
% [3,k] matrix rapresenting 3d landmarks coordinates. 
% T_w_c : the transformation from the world to cameras frame of img1 with respect to img0

% Made as part of the programming assignement
% for Vision Algoritms for Mobile Robotics course, fall 2021. ETH Zurich
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% [p1_1, p1_2, ..., p1_k] % association matrices
% [p2_4, p2_9, ..., p2_k-5] % p1_1 can be associated with an arbitrary p2_i
% [x1,   x2,   ..., xk]     % but each landmark is associated (index-wise) to the relative p1_i 

% we will use a struct 'S' with fields p and X
k = width(S0.p); % number of matches
S.p = zeros(2,k); % 2d coordinates
S.X = zeros(3,k); % 3d landmarks coordinates
k = width(S0.C);
S.C = zeros(2,k);
S.F = zeros(2,k);
S.T = zeros(12,k);

pointTracker = vision.PointTracker('MaxBidirectionalError', params.lambda, ...
                                   'NumPyramidLevels', params.num_pyr_levels, ...
                                   'BlockSize', params.bl_size, ...
                                   'MaxIterations', params.max_its);
initialize(pointTracker,S0.p.',img0)
setPoints(pointTracker,S0.p.'); 
%[points1,points1_validity] = pointTracker(img1);

[trackedKeypoints, isTracked] = step(pointTracker, img0);
S.p = trackedKeypoints(isTracked,:).';
S.X = S0.X(:,isTracked);

% estimateWorldCameraPose is a matlab func that requires double or single inputs
S.p = double(S.p);
S.X = double(S.X);

% Estimate the camera pose in the world coordinate system
[R, T, best_inlier_mask, status] = estimateWorldCameraPose(S.p.', S.X.', params.cam, ...
                                'MaxNumTrials', params.max_num_trials, ...
                                'Confidence', params.conf, ...
                                'MaxReprojectionError', params.max_repr_err);

% Status is a variable that tells if p3p went good or has internal errors
% print it for debugging

% cut the list of keypoints-landmark deleting outliers
S.p = S.p(:,best_inlier_mask);
S0.p = S0.p(:,best_inlier_mask);
S.X = S.X(:,best_inlier_mask);
S.X = S0.X(:,best_inlier_mask);

% Combine orientation and translation into a single transformation matrix
T_W_C_curr = [R, T.'];

% Extract new keyframes
S = extractKeyframes(S0, S, T_W_C_curr(1:3,:), img0, img1, K);
S0.C = S.C;

%%%%%%%%%%%% printo le frames
printRelatuvePose = 0;
if printRelatuvePose
    figure(1)
    hold on
    plotCoordinateFrame(eye(3),zeros(3,1), 0.8);
    text(-0.1,-0.1,-0.1,'Cam 1','fontsize',10,'color','k','FontWeight','bold');
    center_cam2_W = T_W_C_curr * [0 0 0 1]';
    plotCoordinateFrame(T_W_C_curr(1:3,1:3),T_W_C_curr(1:3,4), 0.8);
    text(center_cam2_W(1)-0.1, center_cam2_W(2)-0.1, center_cam2_W(3)-0.1,'Cam 2','fontsize',10,'color','k','FontWeight','bold');
    axis equal
    rotate3d on;
    grid
    title('Cameras relative poses')
end
%%%%%%%%%%%%


S = extractKeyframes(S0, S, T_W_C_curr(1:3,:), img0, img1, K, params);
% extractKeyframes(S, T_C_W, img0, img1, K, params)
S0.C = S.C;

end