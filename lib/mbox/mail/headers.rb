#--
# Copyleft meh. [http://meh.doesntexist.org | meh@paranoici.org]
#
# This file is part of ruby-mbox.
#
# ruby-mbox is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ruby-mbox is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with ruby-mbox. If not, see <http://www.gnu.org/licenses/>.
#++

require 'mbox/mail/headers/status'
require 'mbox/mail/headers/contenttype'

class Mbox
    class Mail
        # Representation of email headers.
        class Headers < Hash
            # Create a Headers object with starting passed headers.
            def initialize (headers={})
                self.merge!(headers)
            end

            def parse (text)
                stream = StringIO.new(text)
                last   = nil

                while !stream.eof? && !(line = stream.readline).chomp.empty?
                    if !line.match(/^\s/)
                        matches = line.match(/^([^:]*):\s*(.*)$/)

                        if !matches
                            next
                        end

                        name  = matches[1]
                        value = matches[2]

                        if self[name]
                            if self[name].is_a?(String)
                                self[name] = [self[name]]
                            end

                            if self[name].is_a?(Array)
                                self[name] << value
                            end
                        else
                            self[name] = value
                        end

                        last = name
                    else
                        if self[last]
                            if self[last].is_a?(String)
                                self[last] << " #{line}"
                            elsif self[last].is_a?(Array)
                                self[last].last << " #{line}"
                            end
                        end
                    end
                end

                self.normalize

                return self
            end

            # Apply normalization to headers.
            #
            # Transforms the Status header to a Status object.
            # Transforms the Content-Type header to a ContentType object.
            def normalize
                if !self['Status'].is_a?(Status)
                    if !self['Status'] || !self['Status'].is_a?(String)
                        self['Status'] = Status.new(false, false)
                    else
                        self['Status'] = Status.new(self['Status'].include?('R'), self['Status'].include?('O'))
                    end
                end

                if !self['Content-Type'].is_a?(ContentType)
                    if !self['Content-Type'] || !self['Content-Type'].is_a?(String)
                        self['Content-Type'] = ContentType.new
                    else
                        self['Content-Type'] = ContentType.parse(self['Content-Type'])
                    end
                end
            end

            def to_s
                result = ''

                self.each {|name, values|
                    [values].flatten.each {|value|
                        result << "#{name}: #{value}\n"
                    }
                }

                return result
            end
        end
    end
end
