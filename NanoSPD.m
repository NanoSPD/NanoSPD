%#########################################
%   NanoSPD Analysis Code v2.4
%
%   Functions and GUI to analyse filopodia co-localisation in NanoSPD Assays
%   Jonathan E. Bird LMG/NIDCD/NIH

%   ##############################################################################
%   Version 1 
%   ##############################################################################
%   Basic functionality achieved. 


%   ##############################################################################
%   Version 2.0 
%   ##############################################################################
%   Major update, complete rewriting of internal code. Ported to GUIDE.
%   File input as individual .TXT or batch .TXT files.
%   Changed internal data storage to a struct array. 
%   Filopodia are now aligned prior to analysis.
%   Added XCorr support
%   Added data reversal flag to file. 
%   Added file export.
%   Implemented experimental variable size block randomization for testing Rho significance.


%   ##############################################################################
%   Version 2.1
%   ##############################################################################
%   Implemented optional background subtraction for Rho analysis (however I the analysis is better without background substraction).
%   Update status window and file export to support Rho, Rho_p, Rho_interact + internal filopodia number
%   Implemented 'Include' flag to include/exclude data in GUI + file-export.
%   Implemented save/load handles.data to/from Matlab binary file.
%   Auto exclude filopodia where bait does not exceeed threshold.
%   Add local prey search at peak (WOBBLE_PEAK)
%   Deprecated get_threshold()
%   Add union vector to output + GUI readout (change colour + text size?)
%   Implemented peak centroid detection where signal is heavily saturated


%   ##############################################################################
%   Version 2.2a
%   ##############################################################################
%   Implemented single data import.
%   Export graphics of line trace.
%   Auto calculate block size dependent upon line trace pixel size
%   Added summary stats in the output file. 
%   Normalize prey after cropping - helps maximize signal for image export. 
%   Use Rho_interact only to detect interaction. 
%   If data exluded, remove images from histogram + XCorr
%   Add function to clear data, and allow a new set to be loaded
%   Improve data filter to reject traces with insfufficient data
%   Measure FWHM of EGFP signal - set as criteria
%   set analysis variables in program.
%   Deprecate Struct Interaction + Union_Interaction. Using Rho signif now
%   differentiate between data exclusion because of short trace vs user


%   ##############################################################################
%   Version 2.3a (RC for LMG rollout)
%   ##############################################################################
%   DONE - deprecated global declarations. Now defined in a struct in the GUIdata handles    
%   DONE - build new options GUI
%   DONE - enumerated classes for data order, correlation, interaction type
%   DONE - deprecate data 'reverse' flag.
%   DONE - fixed Zeiss file loading routine
%   DONE - updated main functions to implement new "options GUI"
%   DONE - fixed "File:Close" function and purging of data struct.
%   DONE - Changed GUI_Settings() to preserve unchanged variables.
%   DONE - inactivate zeiss load when datasets loaded/analyzed.

%   PRELIM - Multicore aware - but not enabled by default
%   DONE - Exports raw amplitude to CSV results file. 


%   ##############################################################################
%   Version 2.4
%   ##############################################################################
%   DONE - increased GUI size and made window resizeable (Win32 systems)
%   DONE - deactivate GUI menu settings option AFTER data is loaded. 
%   DONE - fixed Analyze_Viewtraces() to read Consensus_interact flag
%   DONE - Test load/save .mat routine
%   DONE - Fixed progress slider to count up


%   ##############################################################################
%   POSSIBLE TODO
%   ##############################################################################

%   Export all globals to file .mat save - also - restore for subsequent loading
%   Implement 3rd phalloidin channel? Improve peak finding (use phalloidin signal to verify???)
%   Fix bug when there is only one dataset loaded - initial linetrace does
%   not appear. 
%   Put data into a CLASS?
%   Start splitting functions out from main file. 
%   made interactions YES and NO with enumerated variable....
%   Add minimum FWHM?
%   Pre-allocate structure for loading into memory.?
%   enumerate yes/no for multicore
%   ADD image annotations to exported filopodia images (ID numbers)
%   HEAT MAP on export image, rather than GREEN/RED
%   Options to analyze all data, or just subsets...?

function varargout = NanoSPD(varargin)
% NANOSPD MATLAB code for NanoSPD.fig
%      NANOSPD, by itself, creates a new NANOSPD or raises the existing
%      singleton*.
%
%      H = NANOSPD returns the handle to a new NANOSPD or the handle to
%      the existing singleton*.
%
%      NANOSPD('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in NANOSPD.M with the given input arguments.
%
%      NANOSPD('Property','Value',...) creates a new NANOSPD or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before NanoSPD_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to NanoSPD_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help NanoSPD

% Last Modified by GUIDE v2.5 21-Jun-2016 11:49:18

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @NanoSPD_OpeningFcn, ...
                   'gui_OutputFcn',  @NanoSPD_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before NanoSPD is made visible.
function NanoSPD_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for NanoSPD
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% ##########################################################################
% Create struct to hold "globals", these are no longer declared as global
% ##########################################################################
% ALIGN_WINDOW      % [MIN MAX] (In um), sets the point where the filopodia traces are aligned too. 
% SD               % # of standard deviations to set filopodia significance threshold.
% MEAN_WINDOW      % [MIN MAX] in uM relative to filopodia peak. Sets the window for averaging filopodia background fluoresence.
% CODE_VERSION
% BLOCK_SIZE       % Sets block size for randomization in uM, NOT PIXELS. 
% BLOCK_TRIALS     % How many randomizations to perform for Pearson's signficance test
% PREY_WOBBLE      % (In um), how much the prey and bait can be misaligned, and still judged positive.
% PERCENTILE       % Sets percentile threshold for Pearson's test. Expressed as PERCENTILE/100 
% VIEWLINE_RES     % (in pixels). Sets resolution of View Line Trace bitmap
% VIEWLINE_THICK   % (in pixels), thickness of line trace export
% VIEWLINE_SPACING % (in pixels), spacing of filopodia
% FWHM             % (in um), minimum full width half maximum of bait 
% CORR_TYPE        % Enumerated Class (for fun).'Pearsons' or 'Spearmans'
% INTERACTION_MODE % 1 (Threshold), 2 (Correlation), 3 (Thres + Corr)
% DATA_FORMAT      % 1 (Dist:Bait:Prey), 2 (Dist:Prey:Bait)

handles.globals = struct(   'CODE_VERSION', '2.4',...
                    'ARCHITECTURE', computer,...
                    'MULTICORE', 0,...% 0 for no, 1 for yes
                    'ALIGN_WINDOW', [-2 1],...
                    'MEAN_WINDOW', [-2 -1],...
                    'SD', 3,...
                    'BLOCK_SIZE', 0.2,...
                    'BLOCK_TRIALS', 500,...
                    'PREY_WOBBLE', 0.2,...
                    'PERCENTILE', 99,...
                    'VIEWLINE_RES', 300,...
                    'VIEWLINE_THICK', 4,...
                    'VIEWLINE_SPACING', 18,...
                    'FWHM', 1.5,...
                    'CORR_TYPE', Correlation_Type.Pearson, ...
                    'INTERACTION_MODE', Interaction_Mode.Threshold_plus_Correlation,...
                    'DATA_FORMAT', Data_Type.Linescan_D_P_B);              

% Create struct to hold data. UPDATE CHANGES IN FILE CLOSE CALL BACK TOO
handles.data = struct('Filename', ' ',...
    'FilopodiaID', [],...
    'data_array', [],...
    'data_array_raw', [], ...
    'XCorr', [], ...
    'Max_XCorr', [],...
    'Peaks', [],...
    'Bait_Threshold', [],...
    'Bait_Positive', [],...
    'Prey_Threshold', [],...
    'Prey_Positive', [], ...
    'Max_Bait_Raw', [],...
    'Max_Prey_Raw',[],...
    'Rho_array', [], ...
    'Rho', [], ...
    'Rho_pval', [],...
    'Rho_interact', [],...
    'Consensus_interact', [],...
    'Include', [],... 
    'Exclusion_Criteria', [])       

% Save app_data into the GUI      
guidata(hObject,handles);

% ##########################################################################
% General GUI Prep
% ##########################################################################

% Push analysis summary to the status box. 
output = sprintf('\n%s', 'NanoSPD Filopodia Colocalization Analysis');
output = strcat(output, sprintf('%s %s', ' Version', num2str(handles.globals.CODE_VERSION)));
output = strcat(output, sprintf('\n\n%s', 'Default Analysis Parameters'));
output = strcat(output, sprintf('\nALIGN_WINDOW [%2.1f %2.1f]\nMEAN_WINDOW [%2.1f %2.1f]\nSD %2.1f', handles.globals.ALIGN_WINDOW(1), handles.globals.ALIGN_WINDOW(2), handles.globals.MEAN_WINDOW(1), handles.globals.MEAN_WINDOW(2), handles.globals.SD));
output = strcat(output, sprintf('\nBLOCK_SIZE %2.2f\nBLOCK_TRIALS %u\nPREY_WOBBLE %2.2f\n', handles.globals.BLOCK_SIZE, handles.globals.BLOCK_TRIALS, handles.globals.PREY_WOBBLE));
output = strcat(output, sprintf('\nPERCENTILE %2.2f\nFWHM %2.2f', handles.globals.PERCENTILE/100, handles.globals.FWHM));

set(handles.text1,'String', output);

defaultBackground = get(0,'defaultUicontrolBackgroundColor')
set(handles.figure1,'Color',defaultBackground);
set(handles.uipanel4,'BackgroundColor',defaultBackground);
set(handles.text1,'BackgroundColor',defaultBackground);
set(handles.text2,'BackgroundColor',defaultBackground);
set(handles.text3,'BackgroundColor',defaultBackground);
set(handles.text4,'BackgroundColor',defaultBackground);

set(handles.File_Save,'Enable', 'off');
set(handles.File_Export,'Enable', 'off');
set(handles.Analyze_Run,'Enable', 'off');
set(handles.Analyze_ViewTraces,'Enable', 'off');

set(handles.slider2,'Visible', 'off');
set(handles.checkbox2,'Visible', 'off');
set(handles.axes1,'Visible', 'off');
set(handles.axes2,'Visible', 'off');
set(handles.axes3,'Visible', 'off');
set(handles.text2,'Visible','off');
set(handles.text3,'Visible','off');
set(handles.text4,'Visible','off');

% Make figure resizeable
set(hObject, 'Resize', 'on');


        
% --- Outputs from this function are returned to the command line.
function varargout = NanoSPD_OutputFcn(hObject, eventdata, handles) 

% Get default command line output from handles structure
varargout{1} = handles.output;




% --- Executes during object creation, after setting all properties.
function slider2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --------------------------------------------------------------------
function Menu_File_Callback(hObject, eventdata, handles)
% hObject    handle to Menu_File (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Menu_OpenFilopodiaBatch_Callback(hObject, eventdata, handles)
% This function opens linetrace data exported from ImageJ.
% This is the prefered format, as filopodia are saved in batches. 

% Prompt user for directory location, then get contents
path = uigetdir();
path_dir = dir(fullfile(path, '*.txt')); 
                
[num_files, ~] = size(path_dir);

if num_files == 0
    error('No files to process');
    return; 
end

i = 1;
while i <= num_files
    %Build filename
    filename = fullfile(path,path_dir(i).name);

    %Import data, requires parsing before loading into data struct
    temp = importdata(filename);
    
    %Lose 1st column of data, this is just a row number (ImageJ quirk)
    temp.data(:,1) = [];
    
    %cast to uint16
    %temp.data = uint16(temp.data);
    
    %Perform limited format check of remaining data, columns should be a multiple of 3
    [~, col] = size(temp.data);

    if (rem(col,3) ~= 0) || (col == 0) %or if data size is 0 (shouldnt this be "empty")?     
        error('The input file is incorrectly structured');
        return;
    end

    if i == 1
        %This is first file, therefore just load the filopodia into the data array
        filopodia = 1;
        filopodia_max = col / 3;
        k = 1;
    else   
        %This is the 2nd or more file, find size of existing data array and append to it
        %Get data array size
        [~, current_size, ~] = size(handles.data);
        filopodia_max = current_size + (col / 3);

        %filopodia counter has ALREADY been incremented in previous
        %while loop. Just need to reset the k counter. 
        k = 1;
    end    

    while filopodia <= filopodia_max
        %Read data in
        handles.data(filopodia).Filename = filename;
        handles.data(filopodia).FilopodiaID = k;
        
        if handles.globals.DATA_FORMAT == Data_Type.Linescan_D_B_P
            %load normally (dist, bait, prey).
            handles.data(filopodia).data_array(:,1) = temp.data(:,(k*3)-2);
            handles.data(filopodia).data_array(:,2) = temp.data(:,(k*3)-1); 
            handles.data(filopodia).data_array(:,3) = temp.data(:,(k*3));    
        elseif handles.globals.DATA_FORMAT == Data_Type.Linescan_D_P_B   
            %switch order (dist, prey, bait) 
            handles.data(filopodia).data_array(:,1) = temp.data(:,(k*3)-2);
            handles.data(filopodia).data_array(:,3) = temp.data(:,(k*3)-1); 
            handles.data(filopodia).data_array(:,2) = temp.data(:,(k*3));
        end
            
        % ImageJ line profile scan pads arrays with zeros.
        % Remove them, and then reload to the data struct.
        handles.data(filopodia).data_array = handles.data(filopodia).data_array(any(handles.data(filopodia).data_array,2),:);

        filopodia = filopodia+1; %Increment count
        k = k + 1;
    end

    %Increment counter to next file
    i = i+1; 

end

%Update guidata and also text box with status.
guidata(hObject,handles);
output = sprintf('\n  %u filopodia data sets loaded', filopodia_max);
set(handles.text1,'String', output);
%set(handles.pushbutton1,'Enable', 'on');
set(handles.Analyze_Run,'Enable', 'on');
set(handles.File_Close,'Enable', 'on');
set(handles.File_Open,'Enable', 'off');
set(handles.Menu_OpenFilopodiaBatch,'Enable', 'off');
set(handles.Menu_OpenFilopodiaZeiss,'Enable', 'off');
set(handles.Analyze_Settings,'Enable','off');





    
% --------------------------------------------------------------------
function File_Quit_Callback(hObject, eventdata, handles)
% Easy - just quit.
close all 



% --- Executes on button press in checkbox2.
function checkbox2_Callback(hObject, eventdata, handles)

% Get current button and slider value 
state = get(hObject,'Value');
filopodia = round(get(handles.slider2, 'Value'));

% Update handles.data and save using guidata
handles.data(filopodia).Include = state;

if state == 0
    string = handles.data(filopodia).Exclusion_Criteria; %Read current string, append to it.
    handles.data(filopodia).Exclusion_Criteria = strcat(string, sprintf('\nFilopodium was manually excluded'));    
end

guidata(hObject,handles);

% Call slider2 routine to update GUI
slider2_Callback(hObject, eventdata, handles);



% --------------------------------------------------------------------
function File_Save_Callback(hObject, eventdata, handles)
% This function dumps the handles.data object to an M-file.
% Keeps the current handles.data object in memory, so users can continue
% using program. 

% prompt for file location + save
[file,path] = uiputfile('Analysis.mat', 'Save Analysis As')
save(fullfile(path, file), '-struct', 'handles', 'data')



% --------------------------------------------------------------------
function File_Open_Callback(hObject, eventdata, handles)
%This function loads a previous analysis from a .mat file. 

% prompt for file location 
[file,path] = uigetfile('*.mat', 'Open Previous Analysis')

if file == 0
    %The selection was invalid, do nothing. 
    ;
else
    %Load data. First up, delete the current handles.data struct
    handles.data = []; %set data to an empty array.
    temp = load(fullfile(path, file));
    handles.data = temp.data;
    
    %Save handles.data back to GUIdata
    guidata(hObject,handles);

    %Setup/update GUI for new dataset.
    [~,filopodia_max,~] = size(handles.data)
    
    %Just in case the struct array is empty...
    if filopodia_max >= 1
        set(handles.slider2,'Min', 1, 'Value', 1, 'Max', filopodia_max, 'SliderStep', [1/(filopodia_max-1), 1/(filopodia_max-1)]);
        slider2_Callback(hObject, eventdata, handles); % Call slider2 function to update graphs and status window.
    else
        %There is not data, so generate an error 
    end
end


% --------------------------------------------------------------------
function Menu_Analyze_Callback(hObject, eventdata, handles)



% --------------------------------------------------------------------
function Menu_OpenFilopodiaZeiss_Callback(hObject, eventdata, handles)
% Alternate function to open filopodia scanned using Zeiss's Zen
% application. Only 1 filododia per file for the Zeiss format.

path = uigetdir();
path_dir = dir(fullfile(path, '*.txt')); 
                
[num_files, ~] = size(path_dir);

if num_files == 0
    error('No files to process');
    return; 
end

filopodia = 1; % initiate counter

while filopodia <= num_files
    %Build filename list in directory
    filename = fullfile(path,path_dir(filopodia).name);

    %Import data, first row is automatically parsed out as temp.colheaders
    temp = importdata(filename);
    
    %Perform limited format check of remaining data, there should be 3 columns
    [~, col] = size(temp.data);

    if (col ~= 3) || (col == 0) %or if data size is 0 (shouldnt this be "empty")?     
        error('The input file is incorrectly structured');
        return;
    end
    
    %Read data to data struct
    handles.data(filopodia).Filename = filename;
    handles.data(filopodia).FilopodiaID = filopodia; % because only 1 filo per file in Zeiss format.

    if handles.globals.DATA_FORMAT == Data_Type.Linescan_D_B_P
        handles.data(filopodia).data_array(:,1) = temp.data(:,1);
        handles.data(filopodia).data_array(:,2) = temp.data(:,2); 
        handles.data(filopodia).data_array(:,3) = temp.data(:,3);    
    elseif handles.globals.DATA_FORMAT == Data_Type.Linescan_D_P_B
        handles.data(filopodia).data_array(:,1) = temp.data(:,1);
        handles.data(filopodia).data_array(:,2) = temp.data(:,3); 
        handles.data(filopodia).data_array(:,3) = temp.data(:,2);    
    end
        
    filopodia = filopodia+1; %Increment count
end

%Update guidata and also text box with status.
guidata(hObject,handles);
output = sprintf('\n  %u filopodia data sets loaded', num_files);
set(handles.text1,'String', output);
set(handles.Analyze_Run,'Enable', 'on');
set(handles.File_Close,'Enable', 'on');
set(handles.File_Open,'Enable', 'off');
set(handles.Menu_OpenFilopodiaBatch,'Enable', 'off');
set(handles.Menu_OpenFilopodiaZeiss,'Enable', 'off');
set(handles.Analyze_Settings,'Enable','off');




% --------------------------------------------------------------------
function Analyze_Run_Callback(hObject, eventdata, handles)

% Call the analysis function. 
analyze_filopodia(hObject, eventdata, handles);

% Update GUI
set(handles.Analyze_Run,'Enable', 'off');
set(handles.slider2,'Enable', 'on');
set(handles.checkbox2,'Enable', 'on');
set(handles.File_Save,'Enable', 'on');
set(handles.File_Export,'Enable', 'on');
set(handles.Analyze_ViewTraces,'Enable', 'on');
set(handles.File_Export,'Enable', 'on');
set(handles.axes1,'Visible', 'on');
set(handles.axes2,'Visible', 'on');
set(handles.axes3,'Visible', 'on');
set(handles.slider2,'Visible', 'on');
set(handles.checkbox2,'Visible', 'on');
set(handles.text2,'Visible','on');
set(handles.text3,'Visible','on');
set(handles.text4,'Visible','on');
set(handles.Analyze_Settings,'Enable','off');




% --------------------------------------------------------------------
function Analyze_ViewTraces_Callback(hObject, eventdata, handles)
% Experimental data output display, draws all linescans out and makes a
% TIFF file for export.

% Get size of data struct
[~,filopodia_max,~] = size(handles.data)
filopodia = 1; 
    
output_pos = zeros(filopodia_max*handles.globals.VIEWLINE_SPACING, handles.globals.VIEWLINE_RES,3); %preallocate m x n x 3 array for RGB
output_pos = uint8 (output_pos); %cast for 8bit RGB, for positive interactions
output_neg = output_pos; %create additional image for negative interactions

% Prepare Xq interpolation vector (makes exactly VIEWLINE_RES data points)
step = abs(handles.globals.ALIGN_WINDOW(2) - handles.globals.ALIGN_WINDOW(1))/handles.globals.VIEWLINE_RES; 
Xq =  handles.globals.ALIGN_WINDOW(1): step : handles.globals.ALIGN_WINDOW(2)-(step);

while filopodia <= filopodia_max    
    %check current filopodia is included in analysis
    if handles.data(filopodia).Include == 1
        %Interpolate data to make sure data are all correctly aligned and scaled
        X = handles.data(filopodia).data_array(:,1);
        bait = handles.data(filopodia).data_array(:,2);
        prey = handles.data(filopodia).data_array(:,3);

        % Linear interpolation, scaled for RGB 8-bit
        bait_q = 256 * interp1(X,bait,Xq,'linear'); 
        prey_q = 256* interp1(X,prey,Xq,'linear'); 
 
        %Expand to makes line thicker
        for i = 1:handles.globals.VIEWLINE_THICK-1
            bait_q = [bait_q(1,:); bait_q];
            prey_q = [prey_q(1,:); prey_q];
        end
    
        % Calculate output range
        low = (filopodia*handles.globals.VIEWLINE_SPACING) - (2*handles.globals.VIEWLINE_THICK)
        high = (filopodia*handles.globals.VIEWLINE_SPACING) - handles.globals.VIEWLINE_THICK
    
        if handles.data(filopodia).Consensus_interact == 1
            %data in left hand panel          
            output_pos(low:(low+handles.globals.VIEWLINE_THICK-1),:,2) = bait_q; 
            output_pos(high:(high+handles.globals.VIEWLINE_THICK-1),:,1) = prey_q; 
        else %must be a non-interaciton
            output_neg(low:(low+handles.globals.VIEWLINE_THICK-1),:,2) = bait_q; 
            output_neg(high:(high+handles.globals.VIEWLINE_THICK-1),:,1) = prey_q; 
        end
        
    end
    
    filopodia = filopodia + 1; %increment counter.
end

% Combine both image panel, with a border in the middle
border = uint8(zeros(filopodia_max*handles.globals.VIEWLINE_SPACING,20,3)); %RGB black border
output_pos = horzcat(output_pos, border); % Join matrices
output_pos = horzcat(output_pos, output_neg); %Join with negative interactors

% Show results
figure;
imshow(output_pos);

% Save to file
[file,path] = uiputfile('Summary.tif', 'Save As')

if file ~= 0 % if uiputfile returns SOMETHING.
    imwrite(output_pos, fullfile(path, file), 'tiff');
end
    


% --------------------------------------------------------------------
function File_Close_Callback(hObject, eventdata, handles)
% This function deletes the file database and resets the GUI so that
% another set of files can be loaded.
defaultBackground = get(0,'defaultUicontrolBackgroundColor');

% Deactivate appropriate GUI handes.
set(handles.File_Close,'Enable', 'off');
set(handles.slider2,'Enable', 'off');
set(handles.checkbox2,'Enable', 'off');
set(handles.File_Save,'Enable', 'off');
set(handles.File_Export,'Enable', 'off');
set(handles.Analyze_Run,'Enable', 'off');
set(handles.Analyze_ViewTraces,'Enable', 'off');
set(handles.text1,'String', 'Data buffer cleared');
set(handles.text1,'BackgroundColor',defaultBackground);
set(handles.uipanel4,'BackgroundColor',defaultBackground);


% Clear contents and hide axes
cla(handles.axes1);
cla(handles.axes2);
cla(handles.axes3);
set(handles.axes1,'Visible', 'off');
set(handles.axes2,'Visible', 'off');
set(handles.axes3,'Visible', 'off');

% Hide other GUI components
set(handles.checkbox2,'Visible', 'off');
set(handles.slider2,'Visible', 'off');
set(handles.text2,'Visible','off');
set(handles.text3,'Visible','off');
set(handles.text4,'Visible','off');

% Activate some GUI handles
set(handles.File_Open,'Enable', 'on');
set(handles.Menu_OpenFilopodiaBatch,'Enable', 'on');
set(handles.Menu_OpenFilopodiaZeiss,'Enable', 'on');
set(handles.Analyze_Settings,'Enable','on');

% Delete filopodia database and update GUI struct. Note, do not clear the
% database completely as then I have to redefine the struct here. 

[~, data_size] = size(handles.data)

if data_size >= 2
    handles.data(2:end) = []; % deletes all but the first record. 
end

% We can now assume that there is one record. Wipe it clean. 
% ######## IN FUTURE USE A CLASS AND ADD A WIPE METHOD

handles.data(1).Filename = [];
handles.data(1).FilopodiaID = [];
handles.data(1).data_array = [];
handles.data(1).data_array_raw = [];
handles.data(1).XCorr = [];
handles.data(1).Max_XCorr = [];
handles.data(1).Peaks = [];
handles.data(1).Bait_Threshold = [];
handles.data(1).Bait_Positive = [];
handles.data(1).Prey_Threshold = [];
handles.data(1).Prey_Positive = [];
handles.data(1).Max_Bait_Raw = [];
handles.data(1).Max_Prey_Raw = [];
handles.data(1).Rho_array = [];
handles.data(1).Rho = [];
handles.data(1).Rho_pval = [];
handles.data(1).Rho_interact = [];
handles.data(1).Consensus_interact = [];
handles.data(1).Include = [];
handles.data(1).Exclusion_Criteria = [];


guidata(hObject,handles);



% --------------------------------------------------------------------
function Menu_Help_Callback(hObject, eventdata, handles)
% hObject    handle to Menu_Help (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Help_NanoSPD_Callback(hObject, eventdata, handles)

% Get current figure1 location - in pixels units
pos = get(handles.figure1,'OuterPosition');
pos(3) = 200; pos(4) = 200; %change size, leave position unchanged

% Create dialog box
about_handle = dialog('Units', 'pixels', 'OuterPosition', pos);

% Crate static text panel
message = sprintf('NanoSPD Analysis Utility\nVersion %s\n%s', handles.globals.CODE_VERSION, handles.globals.ARCHITECTURE);
message = strcat(message, sprintf('\n\nJonathan Bird\nNational Institutes of Health\nbirdjo@mail.nih.gov'));
message = strcat(message, sprintf('\n\nNanoSPD is in the public domain'));


text_handle = uicontrol(about_handle,'Style','text','String', message,...
    'Position',[10 10 180 150]);


% --------------------------------------------------------------------
function Analyze_Settings_Callback(hObject, eventdata, handles)

% Call GUI, pass current globals as an argument. 
response = Settings_GUI(handles.globals)

if isstruct(response) == 0
    % return value is not a structure, user cancelled update function.
else
    % update global values
    handles.globals = response; % update globals
   
   %Also update console
   output = sprintf('\n%s', 'Analysis Parameters UPDATED');
   output = strcat(output, sprintf('\n\nALIGN_WINDOW [%2.1f %2.1f]\nMEAN_WINDOW [%2.1f %2.1f]\nSD %2.1f', handles.globals.ALIGN_WINDOW(1), handles.globals.ALIGN_WINDOW(2), handles.globals.MEAN_WINDOW(1), handles.globals.MEAN_WINDOW(2), handles.globals.SD));
   output = strcat(output, sprintf('\nBLOCK_SIZE %2.2f\nBLOCK_TRIALS %u\nPREY_WOBBLE %2.2f\n', handles.globals.BLOCK_SIZE, handles.globals.BLOCK_TRIALS, handles.globals.PREY_WOBBLE));
   output = strcat(output, sprintf('\nPERCENTILE %2.2f\nFWHM %2.2f', handles.globals.PERCENTILE/100, handles.globals.FWHM));

   set(handles.text1,'String', output);
end

% Save return values. 
guidata(hObject,handles);
