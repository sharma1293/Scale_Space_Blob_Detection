function blobDetectionIncreaseFilter(imgPath,sigma,k,n,threshold)
%Reading the image
%img                     = imread('..\data\pandas.jpg');
img                     = imread(imgPath);
imgGray                 = rgb2gray(img);
imgDouble               = im2double(imgGray);
%Decide the initial sigma value
sigmaValue              = [];
filterResponse          = [];
%Make the scale space matrix
tic
for i = 1:n
    sigmaValue          = cat(2,sigmaValue,sigma);
    %Calculate the height of the LoG mask
    h                   = ceil((2*(3*sigma)+1));
    %Create the Log filter. Multiply it by sigma^2 to normalize it and make
    %it scale invarient.
    logFilter           = (sigma^2)*fspecial('log',h,sigma);
    %Calculate the response
    currentResponse     = imfilter(imgDouble,logFilter,'replicate');
    %Square the response so that -Ve minimas also become positive 
    %currentResponse     = power(2,currentResponse);
    currentResponse     = currentResponse.^2;
    %maxResponse = colfilt(currentResponse,[3 3],'sliding',@max);
    %Calculate the matrix which has the maximum values in neighbourhood.
    maxResponse         = ordfilt2(currentResponse,3*3,ones(3,3));
    %Match it with original matrix to get the maxima points
    responseBoolean     = (currentResponse == maxResponse);% & currentResponse>(threshold);
    %Get the matrix with max response and append it to the filter response
    %matrix
    filterResponse      = cat(3,filterResponse,(currentResponse.*responseBoolean));
    %Increase the sigma
    sigma               = sigma*k;
end
%Get the max values of all pixels looking into the depth direction
maxScaleResponse        = max(filterResponse,[],3);
%applying non maxima suppression in 3d
maxScaleResponse3dMax   = ordfilt2(maxScaleResponse,3*3,ones(3,3));
logMax                  = (maxScaleResponse3dMax == maxScaleResponse);
maxScaleResponse        = maxScaleResponse.*logMax;
%Duplicate the max response into a matrix of original size, to match out
%the points where maxima happens
maxResponseAllScales    = repmat(maxScaleResponse,1,1,n);
finalResponseLogicalMat = filterResponse.*(maxResponseAllScales == filterResponse);
%Calculate the index's where maxima points are found
finalInd                = find(finalResponseLogicalMat>threshold);
%Get the coordinates for it
[x y z]                 = ind2sub(size(filterResponse),finalInd);
%Calculate the radius by getting the scale for the point and then
%multiplying it by sqrt(2)
radi                    = sqrt(2)*sigmaValue(z);
toc
%View all points
show_all_circles(imgGray,y,x,radi');
end