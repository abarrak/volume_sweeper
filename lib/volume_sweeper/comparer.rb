require "active_support/core_ext/object/blank"
require_relative "utils/log"

module VolumeSweeper
  module Comparer
    LIST_SEP = "\n     "
    ##
    # Compare unattached block volumes against kubernetes persistent volumes
    # in order to avoid any block volume that as volumeHandler reference,
    # even if not bound to instance.
    #
    # === Docs:
    #
    # The algorithm goes as follows:
    # ```
    #   FOR each_cluster IN oci:
    #     A] Fetch PVs (name, ocid)
    #     B] Fetch BLOCK VOL where attachment = nil
    #     C] Compare A ^ B to Extract Bx NOT IN Ax
    #        THEN:
    #       DEL [C] result
    #   End
    # ```
    #
    def self.process  block_volumes, persistent_volumes
      unused_volumes = []
      active_volumes = []
      counters = { active: 0, unused: 0 }

      return {} if block_volumes.blank? || persistent_volumes.blank?

      block_volumes.each do |vol|
        if persistent_volumes.any? { |p| p[:volumeHandle]&.strip == vol&.strip  }
          counters[:active] += 1
          active_volumes << vol
        else
          counters[:unused] += 1
          unused_volumes << vol
        end
      end

      seperator = -> (str) { str.join(LIST_SEP).prepend LIST_SEP }

      active_list = active_volumes.any? ? seperator.call(active_volumes) : 'None'
      unused_list = unused_volumes.any? ? seperator.call(unused_volumes) : 'None'

      Utils::Log.instance.msg "=> Found #{counters[:active]} still in use."
      Utils::Log.instance.msg "=> Found #{counters[:unused]} unused and should be terminated."
      Utils::Log.instance.msg "=> Details:"
      Utils::Log.instance.msg "===> Active: ", active_list
      Utils::Log.instance.msg "===> Unused: ", unused_list

      { active_ids: active_volumes, unused_ids: unused_volumes }
    end
  end
end
