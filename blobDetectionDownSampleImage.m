function blobDetectionDownSampleImage(imgPath,sigma,k,n,threshold)
img                     = imread(imgPath);
imgGray                 = rgb2gray(img);
imgDouble               = im2double(imgGray);
%Calculate the height of the LoG mask
h                       = ceil((2*(3*sigma)+1));
scaleValue              = [];
filterResponse          = [];
%Create the Log filter. Multiply it by sigma^2 to normalize it and make
%it scale invarient.
logFilter               = (sigma^2)*fspecial('log',h,sigma);
scale                   = sigma;
currentFactor           = 1;
tic
for i = 1:n
    scaleValue = cat(2,scaleValue,scale);
    currentImage = imresize(imgDouble,(1/currentFactor),'bicubic');
    %size(currentImage)
    currentResponse = imfilter(currentImage,logFilter,'replicate');
    %currentResponse = power(2,currentResponse);
    currentResponse     = currentResponse.^2;
    currentResponse = imresize(currentResponse,size(imgDouble),'bicubic');
    % size(currentResponse)
    maxResponse = ordfilt2(currentResponse,3*3,ones(3,3));
    responseBoolean = (currentResponse == maxResponse);
    filterResponse = cat(3,filterResponse,(currentResponse.*responseBoolean));
    currentFactor = currentFactor*k;
    scale = scale*k;
end
maxScaleResponse = max(filterResponse,[],3);
%applying non maxima suppression in 3d
maxScaleResponse3dMax = ordfilt2(maxScaleResponse,3*3,ones(3,3));
%maxScaleResponse3dMax = colfilt(maxScaleResponse,[3 3],'sliding',@max);
logMax = maxScaleResponse3dMax == maxScaleResponse;
maxScaleResponse = maxScaleResponse.*logMax;

maxResponseAllScales = repmat(maxScaleResponse,1,1,n);
finalResponseLogicalMat =filterResponse.*(maxResponseAllScales == filterResponse);

finalInd = find(finalResponseLogicalMat>threshold);
[x y z] = ind2sub(size(filterResponse),finalInd);

radi = sqrt(2)*scaleValue(z);
toc
show_all_circles(imgGray,y,x,radi');
end