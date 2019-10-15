#ifndef LIBRANGEMAP_H_INCLUDED
#define LIBRANGEMAP_H_INCLUDED
#include <fstream>
#include <type_traits>
#include <stddef.h>
#include <string>
#include <vector>
#include <iomanip>


namespace RANGEMAP
{
    template<class T>
    class MAP
    {
        public:
            MAP(T low,T high){
                inRange.reserve(2);
                outRange.reserve(2);
                outRange.push_back(0.0f);
                outRange.push_back(1.0f);
                if(std::is_same<T,char>::value)
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

            std::vector<T> getIRange(){return inRange;}

            std::vector<float> getORange(){return outRange;}

            float THIS(T toMap){
                if(std::is_same<T,char>::value)
                {
                    toMap=convertToRange(toMap);
                }
                float derivitive =toMap/(inRange.at(1)-inRange.at(0));
                float answer= outRange.at(0)+(outRange.at(1)-outRange.at(0))*derivitive;
                if(answer>1){answer=1;};
                if(answer<-1){answer=-1;};
                return answer;
            };


    private:
        std::stringstream SS;
        std::vector<float> inRange;
        std::vector<float>outRange;
        const std::string alpha="ABCDEFGHIJKLMNOPQRSTUVWXYZ";

        int convertToRange(char cvt)
        {
            char c = std::toupper(cvt);
            const int pos = static_cast<int>(alpha.find(c));
            if(pos >=0&&pos <=25)
            {
                return pos + 1 ;
            }
            else
            {
                return 999;
            }
        }
    };

};

#endif // LIBRANGEMAP_H_INCLUDED

