%% -------------------------------------------------------------------
% Descrption : Web file crawler
% Author : Wang Kang
% Mail : goto.champion@gmail.com
% Blog : kang.blog.com
%% -------------------------------------------------------------------
function crawling(website, filetypes, downloadPath)
% prior-rule defined
if website(end) == '/'
    website(end) = [];
end
% initialize container
visitedWebsites = {};
unvisitedWebsites = {website};
downloadedFiles = {};
while ~isempty(unvisitedWebsites)
    % query a new task
    website = unvisitedWebsites{1};
    visitedWebsites = {visitedWebsites{:}, website};
    unvisitedWebsites(1) = [];
    % get files and sub-links
    disp(sprintf('visiting [%d/%d] : %s', length(visitedWebsites), length(visitedWebsites)+length(unvisitedWebsites), website))
    if length(visitedWebsites) == 4
        a = 12;
    end
    [fileLinks, hrefLinks] = exploreWebiste(website);
    % remove links already visited
    fileLinks = trimVisitedLinks(fileLinks, downloadedFiles);
    hrefLinks = trimVisitedLinks(hrefLinks, visitedWebsites);
    % trim repeat links
    fileLinks = unique(fileLinks);
    hrefLinks = unique(hrefLinks);
    % download files
    for i = 1 : length(fileLinks)
        filePath = fileLinks{i};
        [~, filename] = parseFilePath(filePath);
        fileType = getFileTypeSuffix(filename);
        if ~isempty(fileType)
            fileTypeIndex = find(ismember(filetypes, fileType), 1);
            if ~isempty(fileTypeIndex)
                try
                    urlwrite(filePath,strcat(downloadPath, '/', filename),'get',{'term','urlwrite'});
                    downloadedFiles = {downloadedFiles{:}, filePath};
                    disp(sprintf('downloading [%d] : %s', length(downloadedFiles), filePath))
                catch err
                    disp(sprintf('can not download %s, %s', filePath, err.identifier))
                end
            end
        end
    end
    % append tasks
    unvisitedWebsites = {unvisitedWebsites{:}, hrefLinks{:}};
end

%% Remove visted links
function links = trimVisitedLinks(links, visitedLinks)
trimIndex = [];
for i = 1 : length(links)
    alreadyIn = find(ismember(visitedLinks, links(i)), 1);
    if ~isempty(alreadyIn)
        trimIndex = [trimIndex, i];
    end
end
links(trimIndex) = [];

%% Get file type suffix
function fileTypeSuffix = getFileTypeSuffix(filename)
indexes = strfind(filename, '.');
fileTypeSuffix = [];
if ~isempty(indexes)
    index = indexes(end);
    fileTypeSuffix = filename(index+1:end);
    fileTypeSuffix = lower(fileTypeSuffix);
end

%% Parse path to get file path and file name
function [filePath, filename] = parseFilePath(path)
indexes = strfind(path,'/');
filePath = [];
filename = [];
if ~isempty(indexes)
    index = indexes(end);
    filePath = path(1:index);
    filename = path(index+1:end);
end

%% Explore website, collect file links and href links
function [fileLinks, hrefLinks] = exploreWebiste(website)
% load web content
try
    htmlContent = urlread(website);
catch err
    disp(sprintf('can not visit %s, %s', website, err.identifier))
    fileLinks = {};
    hrefLinks = {};
    return;
end

% retrieve keywords
fileLinks = collectKeywords(htmlContent, 'src="')';
hrefLinks = collectKeywords(htmlContent, 'href="')';

% trim repeat links
fileLinks = unique(fileLinks);
hrefLinks = unique(hrefLinks);

trimIndexes = [];
for i = 1 : length(fileLinks)
    % fix file link url
    fileLinks{i} = parseHref(fileLinks{i}, website);
    % trim the file without suffix
    [~, filename] = parseFilePath(fileLinks{i});
    fileType = getFileTypeSuffix(filename);
    if isempty(fileType)
        trimIndexes = [trimIndexes, i];
    end
end
% move it to hrefs
hrefLinks = {hrefLinks{:}, fileLinks{trimIndexes}};
fileLinks(trimIndexes) = [];

trimIndexes = [];
for i = 1 : length(hrefLinks)
    % fix href url
    hrefLinks{i} = parseHref(hrefLinks{i}, website);
    % trim the href with some suffix
    [filepath, filename] = parseFilePath(hrefLinks{i});
    fileType = getFileTypeSuffix(filename);
    if ~isempty(fileType) && strcmpi(filepath, 'http://') ~= 1 % is have file type suffix and the suffix is not http://*.*.com
        isUseless = isempty(find(ismember({'html'}, fileType), 1));
        if isUseless == true
            trimIndexes = [trimIndexes, i];
        end
    end
end
% move it to files
fileLinks = {fileLinks{:}, hrefLinks{trimIndexes}};
hrefLinks(trimIndexes) = [];

%% Parse href
function href = parseHref(href, website)
% add http prefix
if length(href) >= 2 && strcmpi(href(1:2), '//') % if prefix is '//'
    href = strcat('http:', href);
end
if length(href) >= 1 && href(1) == '/' % is prefix is '/'
    indexes = find(ismember(website, '/'));
    if length(indexes) == 2
        href = strcat(website, href);
    else
        rootsite = website(1:indexes(3)-1);
        href = strcat(rootsite, href);
    end
end
if isempty(strfind(href, 'http://')) && isempty(strfind(href, 'https://')) % if not contain 'http' | 'https' prefix
    href = strcat(website, '/', href);
end
% prior-rule defined
if href(end) == '/'
    href(end) = [];
end
    
%% Get keywords in html content, it will collect string that have same prefix
function keywords = collectKeywords(content, prefix)
indexes = strfind(content, prefix);
keywords = {};
for i = 1 : length(indexes)
    keyword = collectKeyword(content, indexes(i)+length(prefix));
    if ~isempty(keyword)
        keywords = {keywords{:}, keyword};
    end
end

%% Get keyword in html content, it will collect characters until meet next symbol"
function keyword = collectKeyword(content, index)
keyword = '';
maxLen = 512;
for i = index : index + maxLen
    if content(i) ~= '"'
        keyword = strcat(keyword, content(i));
    else
        break;
    end
end