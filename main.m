%% -------------------------------------------------------------------
% Descrption : Web file crawler
% Author : Wang Kang
% Mail : goto.champion@gmail.com
% Blog : kang.blog.com
%% -------------------------------------------------------------------
website = 'http://kang.blog.com/'; % the website you wanna crawling
filetypes = {'jpg','png','bmp','gif','tif'}; % the file your wanna download during crawling
downloadPath = 'downloads'; % where to download
if ~isdir(downloadPath)
    mkdir(downloadPath);
end

% start crawling
crawling(website, filetypes, downloadPath)
