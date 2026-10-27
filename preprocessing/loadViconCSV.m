function vicon = loadViconCSV(filepath)
%LOADVICONCSV Load a VICON Nexus "Trajectories" CSV export into a struct.
%
%   vicon = loadViconCSV(filepath)
%
% Expects the standard Nexus trajectory export layout:
%   line 1: "Trajectories"
%   line 2: sample rate (Hz), e.g. "100"
%   line 3: marker names, each repeated 3x with 2 leading blanks
%           (",,5mm:11,,,5mm:12,,," ...)
%   line 4: "Frame,Sub Frame,X,Y,Z,X,Y,Z,..."
%   line 5: units row ("mm,mm,...")
%   line 6+: data, one frame per row
%
% NAME SANITIZING: raw marker names like "5mm:24" or "6mm:base1" include
% a shaft-size prefix that varies file to file. Names are sanitized by
% keeping only the part after the last ':' and, if that's purely numeric,
% prefixing it with 'm' to make a valid field name (so "5mm:24" -> "m24",
% matching the convention computeShaftCenterline.m expects: shaft markers
% expose a numeric ID via regexp on the name, and base markers are
% identified via startsWith(name,'base')). Names that already start with
% a letter (e.g. "base1") are kept as-is.
%
% OUTPUT  vicon (struct):
%   .frame        [N x 1] frame number (1-based, as exported)
%   .time         [N x 1] time, seconds, = (frame-1)/sampleRate
%   .sampleRate   scalar, Hz
%   .names        {1 x M} cell array of sanitized marker names, in
%                 column order (e.g. {'m11','m12',...,'base1',...})
%   .markers      struct, one field per name in .names, each holding
%                 that marker's [N x 3] X/Y/Z data
%
% NOTE: missing/occluded samples are exported by Nexus as blank fields,
% which read in as NaN here -- they are NOT removed or interpolated, so
% downstream code should handle NaNs explicitly (see e.g. dropout checks
% before computing centerlines or rotation angles).

    fid = fopen(filepath, 'r');
    if fid == -1
        error('loadViconCSV:fileNotFound', 'Could not open file: %s', filepath);
    end

    fgetl(fid); % "Trajectories"
    sampleRateLine = fgetl(fid);
    sampleRate = str2double(strtrim(sampleRateLine));

    nameLine = fgetl(fid);
    fgetl(fid); % column-type header line ("Frame,Sub Frame,X,Y,Z,...") -- not needed, structure is fixed
    fgetl(fid); % units line
    fclose(fid);

    % --- parse + sanitize marker names from the name line ---
    nameTokens = strsplit(nameLine, ',');
    rawNames = nameTokens(~cellfun(@isempty, nameTokens));

    names = cell(size(rawNames));
    for k = 1:numel(rawNames)
        raw = rawNames{k};
        colonIdx = strfind(raw, ':');
        if ~isempty(colonIdx)
            suffix = raw(colonIdx(end)+1:end);
        else
            suffix = raw;
        end
        if ~isempty(regexp(suffix, '^\d+$', 'once'))
            names{k} = ['m' suffix];
        else
            names{k} = suffix;
        end
    end

    if numel(unique(names)) ~= numel(names)
        error('loadViconCSV:duplicateNames', ...
            ['Sanitizing produced duplicate marker names: %s. Two raw names ' ...
             'collided after stripping the shaft-size prefix -- check the file header.'], ...
            strjoin(names, ', '));
    end

    % --- read the numeric data block ---
    % readmatrix treats blank fields as NaN automatically and doesn't
    % require building an explicit format string for however many
    % columns this particular export has.
    data = readmatrix(filepath, 'NumHeaderLines', 5);

    nMarkersExpected = numel(names);
    nColsExpected = 2 + 3 * nMarkersExpected;
    if size(data, 2) ~= nColsExpected
        warning('loadViconCSV:columnMismatch', ...
            ['Parsed %d data columns but expected %d (2 + 3 x %d markers). ' ...
             'Marker-name parsing may be out of sync with the data -- check the file header.'], ...
            size(data,2), nColsExpected, nMarkersExpected);
    end

    vicon = struct();
    vicon.frame      = data(:,1);
    vicon.sampleRate = sampleRate;
    vicon.time       = (vicon.frame - vicon.frame(1)) / sampleRate;
    vicon.names      = names;

    vicon.markers = struct();
    for m = 1:nMarkersExpected
        cols = 3 + 3*(m-1) : 3 + 3*(m-1) + 2;
        vicon.markers.(names{m}) = data(:, cols);
    end

end
