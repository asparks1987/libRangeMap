#ifndef LIBRANGEMAP_H_INCLUDED
#define LIBRANGEMAP_H_INCLUDED

#include <stdexcept>
#include <string>
#include <vector>
#include <sstream>
#include <cctype>

namespace RANGEMAP
{
    /**
     * The class RangeMapper is used to map a given value of type T within a certain range
     * to a different range (by default [0, 1]). It also handles both numeric and character values,
     * with characters being mapped to their respective positions in the alphabet.
     */
    template<class T>
    class RangeMapper
    {
    public:
        /**
         * Constructor
         * @param low - lower limit of input range
         * @param high - higher limit of input range
         * @param low_out - lower limit of output range (optional)
         * @param high_out - higher limit of output range (optional)
         */
        RangeMapper(T low, T high, float low_out = 0.0f, float high_out = 1.0f)
        {
            if (high <= low) {
                throw std::invalid_argument("High limit must be greater than low limit.");
            }
            if (high_out <= low_out) {
                throw std::invalid_argument("High output limit must be greater than low output limit.");
            }

            inRange.reserve(2);
            outRange.reserve(2);
            outRange.push_back(low_out);
            outRange.push_back(high_out);

            if (std::is_same<T, char>::value)
            {
                inRange.push_back(convertToRange(low));
                inRange.push_back(convertToRange(high));
            }
            else
            {
                inRange.push_back(low);
                inRange.push_back(high);
            }
        }

        /**
         * Return the input range
         * @return vector containing the input range
         */
        std::vector<T> getInputRange()
        {
            if (inRange.empty()) {
                throw std::out_of_range("Input range is empty.");
            }
            return inRange;
        }

        /**
         * Return the output range
         * @return vector containing the output range
         */
        std::vector<float> getOutputRange()
        {
            if (outRange.empty()) {
                throw std::out_of_range("Output range is empty.");
            }
            return outRange;
        }

        /**
         * Map the given value to the output range
         * @param toMap - value to map
         * @return mapped value
         */
        float map(T toMap)
        {
            if (std::is_same<T, char>::value)
            {
                toMap = convertToRange(toMap);
            }
            float derivative = toMap / (inRange.at(1) - inRange.at(0));
            float answer = outRange.at(0) + (outRange.at(1) - outRange.at(0)) * derivative;

            if (answer > outRange.at(1)) {
                answer = outRange.at(1);
            }
            if (answer < outRange.at(0)) {
                answer = outRange.at(0);
            }
            return answer;
        };

    private:
        std::stringstream SS;
        std::vector<float> inRange;
        std::vector<float> outRange;
        const std::string alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

        /**
         * Converts char to numeric representation for a character (1-26 for A-Z), and 999 for other characters.
         * @param cvt - character to convert
         * @return numeric representation of character
         */
        int convertToRange(char cvt)
        {
            char c = std::toupper(cvt);
            const int pos = static_cast<int>(alpha.find(c));
            if (pos >= 0 && pos <= 25)
            {
                return pos + 1;
            }
            else
            {
                return 999;
            }
        }
    };
};

#endif // LIBRANGEMAP_H_INCLUDED
