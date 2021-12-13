function [T, matchedPoints0, matchedPoints1, landmarks] = twoWiewSFM(img0,img1,K,params)
    figures = 0;
    
    
    cameraParams = cameraParameters('IntrinsicMatrix',K');
    
    % Detect feature points
    %imagePoints0 = detectMinEigenFeatures(img0, 'MinQuality', 0.1);
    imagePoints0 = detectHarrisFeatures(img0, 'MinQuality', params.feature_quality,'FilterSize', params.filt_size);
    imagePoints0 = selectStrongest(imagePoints0, 2000);
    if figures
        % Visualize detected points
        figure
        imshow(img0, 'InitialMagnification', 50);
        title('200 Strongest Corners from the First Image');
        hold on
        plot(selectStrongest(imagePoints0, 200));
    end
    
    % Create the point tracker
    tracker = vision.PointTracker('MaxBidirectionalError', params.lambda, ...
                                   'NumPyramidLevels', params.num_pyr_levels, ...
                                   'BlockSize', params.bl_size, ...
                                   'MaxIterations', params.max_its);

    % Initialize the point tracker
    p0 = imagePoints0.Location;
    initialize(tracker, p0, img0);

    % Track the points
    [imagePoints2, validIdx] = step(tracker, img1);
    matchedPoints0 = p0(validIdx, :);
    matchedPoints1 = imagePoints2(validIdx, :);

    % Estimate the fundamental matrix
    [F, inliers] = estimateFundamentalMatrix(matchedPoints0, matchedPoints1,'Confidence', 99.99999999,'Method', 'RANSAC','DistanceType','Algebraic' );
    %[E, inliers] = estimateEssentialMatrix(matchedPoints0,matchedPoints1, params.cam,'Confidence', 99.99999999);
    matchedPoints0 = matchedPoints0(inliers,:);
    matchedPoints1 = matchedPoints1(inliers,:);

        
    [R,t,validPointsFraction] = relativeCameraPose(F, cameraParams, matchedPoints0, matchedPoints1);
    R
    t
    %stereoParams = stereoParameters(cameraParams,cameraParams,R,t);
    
    % Compute the camera matrices for each position of the camera
    % The first camera is at the origin looking along the Z-axis. Thus, its
    % transformation is identity.
    camMatrix0 = cameraMatrix(cameraParams, eye(3), zeros(3,1));
    
    
    % Compute extrinsics of the second camera
    camMatrix1 = cameraMatrix(cameraParams, R, t);
    
    
   

    if validPointsFraction < 0.99
    warning('[relativeCameraPose] ERROR: relative pose is invalid %f', validPointsFraction);
    end

    %triangulate points
    T = [R, t.'];
    p0_ho = [matchedPoints0, ones(height(matchedPoints0),1)].';
    p1_ho = [matchedPoints1, ones(height(matchedPoints1),1)].';
    %landmarks = triangulate(matchedPoints0, matchedPoints1, camMatrix0, camMatrix1)';
    
    %s = pointCloud(img0, p0_ho, p1_ho, K, T, 1);
    landmarks = linearTriangulation(p0_ho, p1_ho, K*eye(3,4),K*T);

    
%     %[landmarks;landmarks1]
%     size(matchedPoints0)
    %remove points too far away and behind camera
%     i = 1;
%     while i < size(landmarks,2)
%         norm(landmarks(:,i));
%     if landmarks(3,i) < 0 || norm(landmarks(:,i)) > 1000
%        landmarks = landmarks(:,[1:i-1 i+1:end]);
%        matchedPoints0 = matchedPoints0([1:i-1 i+1:end],:);
%        matchedPoints1 = matchedPoints1([1:i-1 i+1:end],:);
%     else
%         i = i + 1;
%     end
%     
%     end
%     size(matchedPoints0)
    
    
    if figures
        % Display inlier matches
        figure
        showMatchedFeatures(img0, img1, matchedPoints0, matchedPoints1);
        title('Epipolar Inliers');
    end
    
    %s = pointCloud(img0, p0_ho, p1_ho, K, T, 1);

end