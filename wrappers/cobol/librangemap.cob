       IDENTIFICATION DIVISION.
       PROGRAM-ID. LIBRANGEMAP.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-INPUT-MIN     PIC S9(09) COMP.
       01  WS-INPUT-MAX     PIC S9(09) COMP.
       01  WS-VALUE         PIC S9(09) COMP.
       01  WS-OUTPUT-MIN    PIC S9(03)V9(09) COMP-2.
       01  WS-OUTPUT-MAX    PIC S9(03)V9(09) COMP-2.
       01  WS-CLIP          PIC X VALUE 'N'.
       01  WS-INPUT-SPAN    PIC S9(09) COMP.
       01  WS-OUTPUT-SPAN   PIC S9(03)V9(09) COMP-2.

       PROCEDURE DIVISION USING
             WS-VALUE WS-INPUT-MIN WS-INPUT-MAX WS-OUTPUT-MIN WS-OUTPUT-MAX WS-CLIP
             RETURNING WS-OUTPUT-SPAN.

       * Placeholder algorithm reference.
       * Map = outputMin + ((value - inputMin) / (inputMax - inputMin)) * (outputMax - outputMin)
       GOBACK.
