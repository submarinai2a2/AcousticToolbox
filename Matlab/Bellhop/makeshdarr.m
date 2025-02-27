function makeshdarr( ARRFIL, freqlist, filetype )

% Make a shade file using the arrivals information
% usage:
% makeshdarr( ARRFIL, freqlist, filetype );
%   ARRFIL is the arrivals files
%   freqlist is a vector of frequencies
%   filetype indicates ascii or binary format
%
% Creates a pressure field, like the
% contents of a Bellhop .SHD file, using the data in a Bellhop
% produced .ARR arrivals file.
% Chris Tiemann Feb. 2001
% mbp: small mods August 2002
% mbp: had wrong sign (conjugated) on e^(-i w t ) term, April 2016

Narrmx = 50;
outfilename = [ ARRFIL '.shd.mat' ]; %###.mat
ARRFIL = [ ARRFIL '.arr' ];
%filetype = 'mat'

switch ( filetype( 1 : 3 ) )
    case ( 'asc' )
        [ Arr, Pos ] = read_arrivals_asc( ARRFIL, Narrmx );
    case ( 'mat' )
        load( outfilename )  % confusing stuff here because same *.mat file used for input and output ...
        % Matlab version of Bellhop has a different ordering
        Arr.A     = permute( Arr.A,     [ 2 3 1 ] );
        Arr.delay = permute( Arr.delay, [ 2 3 1 ] );
        Arr.Narr      = Arr.Narr';
    case ( 'bin' )
       ARRFIL
       Narrmx
        [ Arr, Pos ] = read_arrivals_bin( ARRFIL, Narrmx );
    otherwise
        error( 'Unknown file type' )
end

Nsd = length( Pos.s.depth );    % # source depths
Nrd = length( Pos.r.depth );    % # receiver depths
Nrr = length( Pos.r.range );    % # receiver ranges

%Fields for different frequencies saved in separate files

%Calculate pressure field for different frequencies
for ifreq = 1 : length( freqlist )
    disp( [ 'Calculating pressure field for frequency ' num2str( freqlist( ifreq ) ) ...
        ' Hz.' ] )
    freq = freqlist( ifreq );
    omega = 2 * pi * freq;
    pressure = zeros( 1, Nsd, Nrd, Nrr );
    if Nsd > 1
        for isd = 1 : Nsd
            for ird = 1 : Nrd
                for ir = 1 : Nrr
                    numarr = Arr.Narr( ir, ird, isd );

                    if numarr>0;
                        pressure( 1, isd, ir, ird ) = Arr.A( ir, 1:numarr, ird, isd ) * ...
                            exp( -1i * omega * Arr.delay( ir, 1:numarr, ird, isd ) ).';
                    end %if
                end %ir
            end %ird
        end %isd
    else  % handles case of just one source depth, if arrays are not dimensioned for that
        for ird = 1 : Nrd
            for ir = 1 : Nrr
                numarr = Arr.Narr( ir, ird );

                if numarr>0;
                    pressure( 1, 1, ird, ir ) = Arr.A( ir, 1:numarr, ird ) * ...
                        exp( -1i * omega * Arr.delay( ir, 1:numarr, ird ) ).';
                end %if
            end %ir
        end %ird

        %Save results to file, viewable with plotshd.m
        PlotTitle = '     ';
        PlotType  = 'rectilin  ';
        atten     = 0;
        freqVec   = freq;
        %outfile = [ outfilename num2str( freqlist( ifreq ) ) '.mat' ];
        eval( [ 'save ' outfilename ' PlotTitle PlotType freqVec atten Pos pressure' ] );
    end
end %freq
